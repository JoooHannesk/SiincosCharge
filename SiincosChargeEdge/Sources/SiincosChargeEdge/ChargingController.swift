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
    func start() {
        do {
            try self.backend?.startup()
        } catch {
            self.logger.critical("\(error.localizedDescription)", metadata: ["error": "\(error)"])
            self.shutdown()
        }
        self.startRunLoop()
    }

    /// Start the run loop
    ///
    /// Start the main run loop
    private func startRunLoop() {
        self.runLoopTask?.cancel()
        self.runLoopTask = SimpleLoopTimer.getSimpleLoopTimerWith(interval: 3.0) { [weak self] in
            await self?.runLoop()
        }
    }

    /// Shutdown
    ///
    /// Shutdown gracefully
    func shutdown() {
        self.runLoopTask?.cancel()
        try? self.backend?.shutdown()
        ChargingController.shutdown()
    }

    /// Run Loop
    ///
    /// Charging controller's main run loop
    private func runLoop() async {
        await self.updateChargingPointStatus()
        do {
            try await self.updateChargingSystemInformation()
            try await self.chargingSystem?.updateLoadBalancedCurrent()
        } catch {
            self.handleError(err: error)
        }
    }

    /// Request a charging session
    ///
    /// In case a charging session is requested, it is registered or updated as a charging session if:
    /// - no other charging session is registered or running for the given charging point
    /// - the EV is plugged in, recognized by the charger and the charger is in state ``EVState/pluggedIn``.
    /// - a session is paused, resumed or stopped (finished) only if the requesting member is the owner of the currently registered session
    /// In any other cases, the charging session request is ignored.
    ///
    /// - Parameter session: charging session details
    @discardableResult
    func requestChargingSession(_ session: ChargingSession) async -> ChargingSession? {
        print(session)
        do {
            switch session.status {
            case .running:
                return try await self.handleChargingRequestRunning(request: session)

            case .waiting:
                // Add a new session in case:
                // 1. no other session is registered
                // 2. the car is plugged in
                // TODO: implement
                break

            case .paused:
                // Update an existing session in case:
                // 1. current session owner is the same as the request owner
                // TODO: implement
                break

            case .finished:
                return try await self.handleChargingRequestFinished(request: session)
            }
        } catch {
            self.handleError(err: error)
        }
        return nil
    }


    /// Handle Charging Session Request…
    ///
    /// … for `.running`.
    ///
    /// Add a new session in case:
    /// 1. no other session is registered
    /// 2. the car is plugged in
    ///
    /// Update an existing session in case:
    /// 1. current session is paused - will be set to running
    /// 2. current session owner is the same as the request owner
    ///
    /// - Parameter request: charging session request from backend
    /// - Returns: Charging task that was started.  In case `nil` is returned, activation of the desired task failed.
    @discardableResult
    private func handleChargingRequestRunning(request: ChargingSession) async throws -> ChargingSession? {
        let chargingPointId = request.cpId
        let evPluggedIn = try await self.chargingSystem?.getEvState(chargingPointId: chargingPointId) == .pluggedIn
        let currentChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingTask(by: chargingPointId)

        if currentChargingSession == nil && evPluggedIn {
            return try await self.startCharging(with: request)
        }

        if currentChargingSession?.status == .paused && currentChargingSession?.userName == request.userName {
            return await self.resumeChargingSession(for: chargingPointId)
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
    /// - Returns: Charging task that was finished.  In case `nil` is returned, terminating the desired task failed.
    @discardableResult
    private func handleChargingRequestFinished(request: ChargingSession) async throws -> ChargingSession? {
        guard let currentChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingTask(by: request.cpId) else {
            return nil
        }

        if currentChargingSession.userName == request.userName {
            return try await self.stopChargingSession(for: request.cpId)
        } else {
            return nil
        }
    }

    /// Start a charging session
    ///
    /// Start a charging session for the provided charging poind id.
    ///
    /// - Parameter session: Charging session to start
    /// - Returns: Charging task that was started.  In case `nil` is returned, activation of the desired task failed.
    @discardableResult
    private func startCharging(with session: ChargingSession) async throws -> ChargingSession? {
        var newSession = session
        guard let meterReading = try await self.chargingSystem?.getMeterReading(chargingPointId: session.cpId) else { return nil }
        newSession.startCharging(systemId: self.systemConfig.systemId, startTime: Date(), meterReading: meterReading)
        await self.chargingSystem?.chargingPointContainer.addChargingTask(newSession)
        return await self.chargingSystem?.chargingPointContainer.getChargingTask(by: session.cpId)
    }

    /// Stop a running charging session
    ///
    /// Stop a running charging session for the provided charging poind id. Notify the backend to write a charging session receipt.
    ///
    /// - Parameter cpId: Charging Point Id
    /// - Returns: Charging task that was finished.  In case `nil` is returned, terminating the desired task failed.
    func stopChargingSession(for cpId: UInt8) async throws -> ChargingSession? {
        guard var runningChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingTask(by: cpId),
              let meterReading = try await self.chargingSystem?.getMeterReading(chargingPointId: cpId) else {
            return nil
        }
        runningChargingSession.finishCharging(endTime: Date(), meterReading: meterReading)
        await self.chargingSystem?.chargingPointContainer.updateChargingTask(runningChargingSession)
        self.backend?.writeChargingSessionReceipt(for: runningChargingSession)
        return await self.chargingSystem?.chargingPointContainer.removeChargingTask(by: cpId)
    }

    /// Pause a running charging session
    ///
    /// - Parameter cpId: Charging Point Id
    func pauseChargingSession(for cpId: UInt8) -> ChargingSession? {
        // TODO: implement
        return nil
    }

    /// Resume a running charging session
    ///
    /// - Parameter cpId: Charging Point Id
    /// - Returns: Charging task that was resumed. In case `nil` is returned, activation of the desired task failed.
    @discardableResult
    private func resumeChargingSession(for cpId: UInt8) async -> ChargingSession? {
        if var runningChargingSession = await self.chargingSystem?.chargingPointContainer.getChargingTask(by: cpId) {
            runningChargingSession.resumeCharging()
            await self.chargingSystem?.chargingPointContainer.updateChargingTask(runningChargingSession)
        }
        return await self.chargingSystem?.chargingPointContainer.getChargingTask(by: cpId)
    }

    /// Update Charging Points Status
    ///
    /// Update charging system status information in backend by
    /// collecting all charging point status information.
    private func updateChargingPointStatus() async {
        do {
            if let cpsStatus = try await self.chargingSystem?.systemStatus {
                self.backend?.updateChargingPointStatus(with: cpsStatus)
            }

            if let chargingTasks = await self.chargingSystem?.chargingPointContainer.chargingTasks {
                self.backend?.updateChargingTasks(with: chargingTasks)
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
        self.logger.info("\(LogMessages.sysInfo)\n\(chargingSystemInformation.description)")
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
        }
    }

    /// Restart System
    ///
    /// Completely restart the system:
    /// - exit application
    /// - restart OS
    ///
    /// - Note: In case an error is thrown, restarting the system is a good idea.
    /// Thrown errors mainly originate from bus communication failures and therefore render the system unmanoeuvrable which requires a restart.
    /// Status errors from EV chargers are generally not registered in ``ChargingController/sysError``, every charger has it's own way to communicate an
    /// error or warning.
    func restartSystem() {
        self.sysError = nil // Pointless...
        logger.info("\(LogMessages.restartMsg)")
        // TODO: implement
        // reboot system with command: "nohup bash -c 'sleep 8 && systemctl reboot' &"
        self.shutdown()
    }

    // MARK: - static methods

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
    static private func shutdown() {
        logger.info("\(LogMessages.goodbyMsg)")
        exit(0)
    }

}
