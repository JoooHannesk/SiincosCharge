//
//  ChargingController.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.05.26.
//

import Foundation


actor ChargingController {

    let systemConfig: SystemConfig
    var backend: BackendController? = nil
    var chargingSystem: ChargingSystem? = nil
    var sysError: SystemError? = nil
    var runLoopTask: Task<Void, Never>? = nil
    private var opQueue: Task<Void, Never>? = nil

    /// Logger
    ///
    /// The application-wide main logger
    private let logger = ComponentSupplier.mainLogger

    /// Init phase
    ///
    /// Load required assets and log errors. Does not connect to the backend or
    /// start the run loop; call ``start()`` for that.
    /// - Parameter systemConfig: system configuration to use, optional; if left blanc the config loaded from file will be used
    init(systemConfig: SystemConfig? = nil) async {
        print(LogMessages.welcomMsg)
        self.logger.info("\(LogMessages.welcomMsg)")

        self.systemConfig = systemConfig ?? Self.loadSystemConfig()
        self.backend = ThingsBoardBackend(chargingController: self)

        do {
            try self.chargingSystem = await ChargingSystem(config: self.systemConfig as DeviceConfig)
        } catch {
            self.logger.critical("\(error.localizedDescription)", metadata: ["error": "\(error)"])
        }
    }

    /// Start-up phase
    ///
    /// Connect to the backend and start the main run loop.
    /// In case of critical errors, shut down.
    func start() async {
        do {
            try self.backend?.startup()
        } catch {
            self.logger.critical("\(error.localizedDescription)", metadata: ["error": "\(error)"])
            await self.shutdown()
        }
        self.startRunLoop()
    }

    /// Start the run loop
    ///
    /// Start the main run loop
    private func startRunLoop() {
        self.runLoopTask?.cancel()
        self.runLoopTask = SimpleLoopTimer.getSimpleLoopTimerWith(interval: 3.0) { [weak self] in
            guard let self else { return }
            await self.enqueue { await self.runLoop() }.value
        }
    }

    /// Enqueue an operation on the serial pipeline
    ///
    /// Run `op` strictly after all previously enqueued operations have finished. Run loop
    /// iterations and charging session requests share this pipeline, so a request can never
    /// interleave with a half-finished run loop iteration (actors are reentrant at suspension
    /// points, which would otherwise let the loop overwrite the request's device commands
    /// with stale decisions).
    private func enqueue<T: Sendable>(_ op: @escaping @Sendable () async -> T) -> Task<T, Never> {
        let previous = self.opQueue
        let task = Task {
            await previous?.value
            return await op()
        }
        self.opQueue = Task { _ = await task.value }
        return task
    }

    /// Run Loop
    ///
    /// Charging controller's main run loop
    private func runLoop() async {
        await self.updateChargingPointStatus()
        do {
            try await self.updateChargingSystemInformation()
            try await self.chargingSystem?.updateLoadBalancedCurrent()
            try await self.executeChargingSessions()
        } catch {
            self.handleError(err: error)
        }
    }

    // MARK: - Charging Session Execution

    /// Execute Charging Session
    ///
    /// Iterate through the all defined charging points and check if charging sessions are registered. Execute these charging sessions.
    /// In case there is no charging session registered, lock this charging point and provide a default current setpoint.
    ///
    /// - Note: ModbusRTU devices (which are currently in use here) often require to permanently write into their registers to stay awake and to prevent them
    /// from throwing a communication error. Therefore, we continuously disable charging and provide a default current setpoint value for all chargers which are
    /// currently not involved in a charging session.
    private func executeChargingSessions() async throws {
        guard let chargingPoints = await self.chargingSystem?.chargingPointContainer.chargingPoints.values,
        let defaultChargingCurrent = self.chargingSystem?.defaultChargingCurrent else {
            self.logger.critical("\(LogMessages.noChargingPointsFound)")
            self.shutdownNow()
            return
        }
        for chargingPoint in chargingPoints {
            if let chargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: chargingPoint.cpId) {
                switch chargingSession.status {
                case .running:
                    try await self.executeChargingSessionRunning(chargingSession)

                case .paused:
                    try await self.executeChargingSessionPaused(chargingSession)

                case .scheduled:
                    try await self.executeChargingSessionScheduled(chargingSession)

                case .finished:
                    try await self.executeChargingSessionFinished(chargingSession)
                }
            } else {
                try await self.setChargingPoint(chargingPoint.cpId, to: .disabled, with: defaultChargingCurrent)
            }
        }
    }

    /// Execute running charging Session
    ///
    /// Enable the corresponding EV charger and update the charging session with the current meter reading.
    /// Perform the following checks to terminate a running charging session gracefully:
    /// 1. Check for an ev unplugged event
    /// 2. Check if `endTime` is provided and finish charging session if it is in the past
    private func executeChargingSessionRunning(_ session: ChargingSession) async throws {
        var runningChargingSession = session

        // Enable charging point
        try await self.setChargingPoint(runningChargingSession.cpId, to: .enabled, with: runningChargingSession.chargingCurrentSetpoint)

        // Update charging session with meter reading
        guard let meterReading = try await self.chargingSystem?.getMeterReading(chargingPointId: runningChargingSession.cpId) else { return }
        runningChargingSession.update(with: meterReading)
        try await self.handelChargingSession(action: .update, session: runningChargingSession)

        // Check for ev unplugged event
        if try await self.chargingSystem?.getEvState(chargingPointId: runningChargingSession.cpId) == .unplugged {
            try await self.stopChargingSession(for: runningChargingSession.cpId)
        }

        // Check for `endTime`
        if let endTime = runningChargingSession.endTime, endTime < Date() {
            try await self.stopChargingSession(for: runningChargingSession.cpId)
        }
    }

    /// Execute pausing charging Session
    ///
    /// Disable the corresponding EV charger. Perform the following checks to terminate a running charging session gracefully:
    /// 1. Check for an ev unplugged event
    /// 2. Check if `endTime` is provided and finish charging session if it is in the past
    private func executeChargingSessionPaused(_ session: ChargingSession) async throws {
        // Disable Charging point
        try await self.setChargingPoint(session.cpId, to: .disabled, with: session.chargingCurrentSetpoint)

        // Check for ev unplugged event
        if try await self.chargingSystem?.getEvState(chargingPointId: session.cpId) == .unplugged {
            try await self.stopChargingSession(for: session.cpId)
        }

        // Check for `endTime`
        if let endTime = session.endTime, endTime < Date() {
            try await self.stopChargingSession(for: session.cpId)
        }
    }

    /// Execute scheduled charging Session
    ///
    /// Disable the corresponding EV charger. Perform the following checks to terminate a running charging session gracefully:
    /// 1. Check for an ev unplugged event
    ///
    /// Perform the following checks to start the scheduled charging session:
    /// 1. Check if `startTime` is in the past and start a new charging session
    private func executeChargingSessionScheduled(_ session: ChargingSession) async throws {
        // Disable Charging point
        try await self.setChargingPoint(session.cpId, to: .disabled, with: session.chargingCurrentSetpoint)

        // Check for ev unplugged event
        if try await self.chargingSystem?.getEvState(chargingPointId: session.cpId) == .unplugged {
            try await self.stopChargingSession(for: session.cpId)
        }

        // Check for `startTime`
        if let startTime = session.startTime, startTime < Date() {
            try await self.handelChargingSession(action: .remove, session: session)
            try await self.startChargingSession(session)
        }

    }

    /// Execute finish charging Session
    ///
    /// Disable the corresponding EV charger, tell the backend to write a charging session receipt
    /// and remove the current charging session from the executor.
    private func executeChargingSessionFinished(_ session: ChargingSession) async throws {
        try await self.setChargingPoint(session.cpId, to: .disabled, with: session.chargingCurrentSetpoint)
        self.backend?.writeChargingSessionReceipt(for: session)
        try await self.handelChargingSession(action: .remove, session: session)
    }


    // MARK: - Charging Session Requests

    /// Request a charging session
    ///
    /// In case a charging session is requested, it is registered or updated as a charging session if:
    /// - no other charging session is registered or running for the given charging point
    /// - the EV is plugged in, recognized by the charger and the charger is in state ``EVState/pluggedIn``.
    /// - a session is paused, resumed or stopped (finished) only if the requesting member is the owner of the currently registered session
    /// In any other cases, the charging session request is ignored.
    ///
    /// - Parameter session: charging session details
    ///
    /// - Note: The request is enqueued on the serial pipeline and executes right after the
    /// currently running run loop iteration (if any), so it cannot be overwritten by
    /// in-flight stale run loop decisions. After the request is processed, the charging point
    /// status is published to the backend immediately instead of waiting for the next run loop tick.
    @discardableResult
    func requestChargingSession(_ session: ChargingSession) async -> ChargingSession? {
        await self.enqueue { await self.processChargingSessionRequest(session) }.value
    }

    /// Process a charging session request
    ///
    /// Executes the request as described in ``requestChargingSession(_:)``. Must only be
    /// called through the serial pipeline (see ``enqueue(_:)``).
    private func processChargingSessionRequest(_ session: ChargingSession) async -> ChargingSession? {
        var requestedSession: ChargingSession? = nil
        do {
            switch session.status {
            case .running:
                requestedSession = try await self.handleChargingRequestRunning(request: session)

            case .scheduled:
                requestedSession = try await self.handleChargingRequestScheduled(request: session)

            case .paused:
                requestedSession = try await self.handleChargingRequestPausing(request: session)

            case .finished:
                requestedSession = try await self.handleChargingRequestFinished(request: session)
            }
            try await self.executeChargingSessions()
            await self.updateChargingPointStatus()
        } catch {
            self.handleError(err: error)
        }
        return requestedSession
    }


    /// Handle Charging Session Request…
    ///
    /// … for `.running`.
    ///
    /// Add a new session in case:
    /// 1. no other session is registered
    ///
    /// Update an existing session in case:
    /// 1. current session is paused - will be set to running
    /// 2. current session owner is the same as the request owner
    ///
    /// - Parameter request: charging session request from backend
    /// - Returns: Charging session that was started.  In case `nil` is returned, activation of the desired session failed.
    @discardableResult
    private func handleChargingRequestRunning(request: ChargingSession) async throws -> ChargingSession? {
        let currentChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: request.cpId)

        if currentChargingSession == nil && !request.userName.isEmpty {
            return try await self.startChargingSession(request)
        }

        if currentChargingSession?.status == .paused && currentChargingSession?.userName == request.userName {
            return try await self.resumeChargingSession(for: request.cpId)
        }
        return nil
    }

    /// Handle Charging Session Request…
    ///
    /// … for `.scheduled`.
    ///
    /// Add a new session in case:
    /// 1. no other session is registered
    ///
    /// - Parameter request: charging session request from backend
    /// - Returns: Charging session that was scheduled.  In case `nil` is returned, activation of the desired session failed.
    @discardableResult
    private func handleChargingRequestScheduled(request: ChargingSession) async throws -> ChargingSession? {
        let currentChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: request.cpId)

        if currentChargingSession == nil && !request.userName.isEmpty {
            return try await self.scheduleChargingSession(request)
        }
        return nil
    }

    /// Handle Charging Session Request…
    ///
    /// … for `.finished`.
    ///
    /// Make sure current session and request share the same owner, otherwise ignore the request.
    /// Gracefully end a charging session, generate a session receipt, and forward it to the backend for safe keeping.
    ///
    /// - Parameter request: charging session request from backend
    /// - Returns: Charging session that was finished.  In case `nil` is returned, terminating the desired session failed.
    @discardableResult
    private func handleChargingRequestFinished(request: ChargingSession) async throws -> ChargingSession? {
        guard let currentChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: request.cpId) else {
            return nil
        }

        if currentChargingSession.status != .finished && currentChargingSession.userName == request.userName {
            return try await self.stopChargingSession(for: request.cpId)
        } else {
            return nil
        }
    }

    /// Handle Charging Session Request…
    ///
    /// … for `.paused`.
    ///
    /// Update an existing session in case:
    /// 1. current session is running - will be set to running
    /// 2. current session owner is the same as the request owner
    ///
    /// - Parameter request: charging session request from backend
    /// - Returns: Charging session that was started.  In case `nil` is returned, activation of the desired session failed.
    @discardableResult
    private func handleChargingRequestPausing(request: ChargingSession) async throws -> ChargingSession? {
        guard let currentChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: request.cpId) else {
            return nil
        }

        if currentChargingSession.status == .running && currentChargingSession.userName == request.userName {
            return try await self.pauseChargingSession(for: request.cpId)
        } else {
            return nil
        }
    }

    /// Start a charging session
    ///
    /// Start a charging session for the provided charging poind id.
    ///
    /// - Parameter session: Charging session to start
    /// - Returns: Charging session that was started.  In case `nil` is returned, activation of the desired session failed.
    @discardableResult
    private func startChargingSession(_ session: ChargingSession) async throws -> ChargingSession? {
        var newSession = session
        guard let meterReading = try await self.chargingSystem?.getMeterReading(chargingPointId: session.cpId) else { return nil }
        newSession.startCharging(systemId: self.systemConfig.systemId, startTime: Date(), meterReading: meterReading)
        let chargingSession = try await self.handelChargingSession(action: .add, session: newSession)
        self.logger.info("\(LogMessages.chargingSessionRequest)\(chargingSession, default: "")")
        return chargingSession
    }

    /// Schedule a charging session
    ///
    /// Schedule a charging session for the provided charging point id
    ///
    /// - Parameter session: Charging session to start
    /// - Returns: Charging session that was started.  In case `nil` is returned, activation of the desired session failed.
    @discardableResult
    private func scheduleChargingSession(_ session: ChargingSession) async throws -> ChargingSession? {
        var newSession = session
        if let start = newSession.startTime, let end = newSession.endTime, start > Date(), end > Date(), end > start {
            newSession.scheduleCharging(systemId: self.systemConfig.systemId, startTime: start, endTime: end)
            let chargingSession = try await self.handelChargingSession(action: .add, session: newSession)
            self.logger.info("\(LogMessages.chargingSessionRequest)\(chargingSession, default: "")")
            return chargingSession
        }
        return nil
    }

    /// Stop a running charging session
    ///
    /// Stop a running charging session for the provided charging poind id. Notify the backend to write a charging session receipt.
    ///
    /// - Parameter cpId: Charging Point Id
    /// - Returns: Charging session that was finished
    @discardableResult
    private func stopChargingSession(for cpId: UInt8) async throws -> ChargingSession? {
        guard var runningChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: cpId),
              let meterReading = try await self.chargingSystem?.getMeterReading(chargingPointId: cpId) else {
            return nil
        }
        runningChargingSession.finishCharging(endTime: Date(), meterReading: meterReading)
        let chargingSession = try await self.handelChargingSession(action: .update, session: runningChargingSession)
        self.logger.info("\(LogMessages.chargingSessionRequest)\(chargingSession, default: "")")
        return chargingSession
    }

    /// Pause a running charging session
    ///
    /// - Parameter cpId: Charging Point Id
    /// - Returns: Charging session that was paused
    @discardableResult
    private func pauseChargingSession(for cpId: UInt8) async throws -> ChargingSession? {
        guard var runningChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: cpId) else {
            return nil
        }
        runningChargingSession.pauseCharging()
        let chargingSession = try await self.handelChargingSession(action: .update, session: runningChargingSession)
        self.logger.info("\(LogMessages.chargingSessionRequest)\(chargingSession, default: "")")
        return chargingSession
    }

    /// Resume a running charging session
    ///
    /// - Parameter cpId: Charging Point Id
    /// - Returns: Charging session that was resumed. In case `nil` is returned, activation of the desired session failed.
    @discardableResult
    private func resumeChargingSession(for cpId: UInt8) async throws -> ChargingSession? {
        guard var runningChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingSession(by: cpId) else {
            return nil
        }
        runningChargingSession.resumeCharging()
        let chargingSession = try await self.handelChargingSession(action: .update, session: runningChargingSession)
        self.logger.info("\(LogMessages.chargingSessionRequest)\(chargingSession, default: "")")
        return chargingSession
    }

    /// Terminate all charging sessions
    ///
    /// Stop all running charging sessions gracefully.
    func terminateChargingSessions() async throws {
        guard let chargingSessions = await self.chargingSystem?.chargingPointContainer.chargingSessions.values else {
            return
        }
        for chargingSession in chargingSessions {
            try await self.stopChargingSession(for: chargingSession.cpId)
        }
    }

    // MARK: - Handle Charging Sessions

    /// Charging Session Handling Actions
    private enum ChargingSessionHandlingActions {
        case add
        case update
        case remove
    }

    /// Handle Charging Session
    ///
    /// Add, update or remove a charging session from the charging system.
    ///
    /// - Parameters:
    ///   - action: Action to execute: add, update or remove
    ///   - session: the charging session to handle
    ///
    /// - Returns: the charging session that was handled
    ///
    /// - Note: The charging session that is returned is requested from the charging system after it was processed (added, updated or removed). If a charging session was
    /// removed `nil` is going top be returned.
    @discardableResult
    private func handelChargingSession(action: ChargingSessionHandlingActions, session: ChargingSession) async throws -> ChargingSession? {
        switch action {
        case .add:
            await self.chargingSystem?.chargingPointContainer.addChargingSession(session)
        case .update:
            await self.chargingSystem?.chargingPointContainer.updateChargingSession(session)
        case .remove:
            await self.chargingSystem?.chargingPointContainer.removeChargingSession(by: session.cpId)
        }
        return await self.chargingSystem?.chargingPointContainer.getChargingSession(by: session.cpId)
    }

    // MARK: - Charging Point Commands

    /// Set Charging Point Command
    ///
    /// Enable or disable a charging point and set the desired maximum current setpoint.
    ///
    /// - Parameters:
    ///   - cpId: Charging point id
    ///   - chargingPermission: Grant or deny charging permission (enable or disable charging at this charging point)
    ///   - currentSetpoint: Set maximum charging current setpoint
    ///
    /// - Returns: Tuple containing the charging permission status and the charging current setpoint acknowledged by the charging point.
    @discardableResult
    private func setChargingPoint(_ cpId: UInt8, to chargingPermission: Status, with currentSetpoint: Measurement<UnitElectricCurrent>) async throws -> (cpChargingPermission: Status?, cpChargingCurrentSetpoint: Measurement<UnitElectricCurrent>?) {
        let chargingPermission = try await self.chargingSystem?.setChargingPermission(to: chargingPermission, for: cpId)
        let chargingCurrentSetpoint = try await self.chargingSystem?.setChargingCurrentSetpoint(to: currentSetpoint, for: cpId)
        return (chargingPermission, chargingCurrentSetpoint)
    }

    // MARK: - Backend involved Tasks

    /// Update Charging Points Status
    ///
    /// Update charging system status information in backend by
    /// collecting all charging point status information.
    private func updateChargingPointStatus() async {
        do {
            if let cpsStatus = try await self.chargingSystem?.systemStatus {
                self.backend?.updateChargingPointStatus(with: cpsStatus)
            }
            if let chargingPointIds = await self.chargingSystem?.chargingPointContainer.chargingPoints.keys,
               let chargingSessions = await self.chargingSystem?.chargingPointContainer.chargingSessions.values {
                self.backend?.updateChargingSessions(chargingPointIds: chargingPointIds, chargingSessions: chargingSessions)
            }
        } catch {
            self.handleError(err: error)
        }
    }

    /// Update Charging System Information
    ///
    /// Update charging system information in backend. This includes:
    /// - app version
    /// - ev charger model
    /// - power meter model
    /// - total number of charging points
    /// - max. installation line current (amperes)
    /// - load balanced max. current
    /// - system error
    private func updateChargingSystemInformation() async throws {
        let chargingSystemInformation = ChargingSystemInformation(
            appVersion: AppConstants.version,
            chargerModel: self.systemConfig.chargerModel,
            meterModel: self.systemConfig.meterModel,
            chargingPoints: self.systemConfig.lineLength,
            chargingPointsCharging: try await self.chargingSystem?.chargingPointsCharging ?? 0,
            lineMaxCurrent: self.systemConfig.lineMaxCurrent,
            loadBalancedMaxCurrent: await self.chargingSystem?.loadBalancedMaxCurrent ?? Measurement(value: 0.0, unit: UnitElectricCurrent.amperes),
            sysError: self.sysError
        )
        self.backend?.updateChargingSystemInformation(with: chargingSystemInformation)
    }

    /// Handle Error
    ///
    /// Handle the error by
    /// - converting it to the project specific ``SystemError``
    /// - set local member
    /// - log it
    private func handleError(err: Error) {
        self.sysError = err as? SystemError
        if let sysError = self.sysError {
            self.logger.error("\(String(describing: sysError.localizedDescription))", metadata: ["error": "\(sysError)"])
        } else {
            self.logger.error("\(err.localizedDescription)", metadata: ["error": "\(err)"])
        }
    }


    // MARK: - Maintenance Methods

    /// Shutdown
    ///
    /// Shutdown gracefully.
    ///
    /// Stops the run loop, then — strictly after any in-flight run loop iteration
    /// (see ``enqueue(_:)``) — terminates all charging sessions and runs one final
    /// execution pass so chargers are disabled, receipts are written and the final
    /// status reaches the backend before it disconnects.
    func shutdown() async {
        self.runLoopTask?.cancel()
        await self.enqueue {
            do {
                try await self.terminateChargingSessions()
                try await self.executeChargingSessions()
            } catch {
                await self.handleError(err: error)
            }
            await self.updateChargingPointStatus()
        }.value
        self.shutdownNow()
    }

    /// Immediate shutdown without draining the serial pipeline
    ///
    /// Safe to call from within a pipelined operation (see ``enqueue(_:)``),
    /// where the graceful ``shutdown()`` would deadlock waiting on itself.
    private func shutdownNow() {
        self.runLoopTask?.cancel()
        try? self.backend?.shutdown()
        ChargingController.shutdown()
    }

    // MARK: - Static Methods

    static let logger = ComponentSupplier.mainLogger

    /// Load System Config
    ///
    /// Load system config from file.
    /// Abort on error, because the system is not operational without a valid config.
    static private func loadSystemConfig() -> SystemConfig {
        let systemConfig: SystemConfig
        do {
            systemConfig = try ComponentSupplier.getSystemConfig()
        } catch {
            logger.critical("\(String(describing: error.localizedDescription))", metadata: ["error": "\(error)"])
            fatalError("\(String(describing: error.localizedDescription))")
        }
        return systemConfig
    }

    /// Shutdown
    ///
    /// Shutdown system gracefully
    /// - Parameter exitCode: The exit code with which to terminate the application. A value of 0 typically
    ///                       indicates successful completion, while nonzero values indicate an error.
    static func shutdown(exitCode: Int32 = 0) {
        logger.info("\(LogMessages.goodbyMsg)")
        exit(exitCode)
    }
}
