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

    /// Init and start-up phase
    ///
    /// Load required assets and log errors. In case of critical errors, shut down.
    init() async {
        print(LogMessages.welcomMsg)
        self.logger.info("\(LogMessages.welcomMsg)")

        self.systemConfig = Self.loadSystemConfig()
        self.backend = ThingsBoardBackend(chargingController: self)

        do {
            try self.chargingSystem = await ChargingSystem(config: self.systemConfig as DeviceConfig)
            try self.backend?.startup()
        } catch {
            self.logger.critical("\(error.localizedDescription)", metadata: ["error": "\(error)"])
            self.shutdown()
        }
        try? await Task.sleep(for: .seconds(5))
        self.startRunLoop()

    }

    /// Start the run loop
    ///
    /// Start the main run loop
    func startRunLoop() {
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
    func runLoop() async {
        // TODO: implement
        print("main runloop called")
        self.logger.info("main runloop called") // TODO: remove
        await self.updateChargingPointStatus()
        do {
            try await self.updateChargingSystemInformation()
            try await self.chargingSystem?.updateLoadBalancedCurrent()
        } catch {
            self.handleError(err: error)
        }
    }

    /// Start a charging session
    ///
    /// Start a charging session for the provided charging poind id.
    ///
    /// - Parameter cpId: Charging Point Id
    ///
    /// - Note: In case the charging point already has a running charging session, the request will be
    /// ignored. If a charging session is paused, it won't be resumed. Use
    /// ``ChargingController/resumeChargingSession(for:)`` instead.
    func startChargingSession(for cpId: UInt8) {
        // TODO: implement
    }

    /// Stop a running charging session
    ///
    /// Stop a running charging session for the provided charging poind id. Stopping
    /// a charging session invokes writing a charging session receipt.
    ///
    /// - Parameter cpId: Charging Point Id
    func stopChargingSession(for cpId: UInt8) {
        // TODO: implement
    }

    /// Pause a running charging session
    ///
    /// - Parameter cpId: Charging Point Id
    func pauseChargingSession(for cpId: UInt8) {
        // TODO: implement
    }

    /// Resume a running charging session
    ///
    /// - Parameter cpId: Charging Point Id
    func resumeChargingSession(for cpId: UInt8) {
        // TODO: implement
    }

    /// Update Charging Points Status
    ///
    /// Update charging system status information in backend by
    /// collecting all charging point status information.
    func updateChargingPointStatus() async {
        do {
            if let cpsStatus = try await self.chargingSystem?.systemStatus {
                self.backend?.updateChargingPointStatus(with: cpsStatus)
                //self.sysError = nil // TODO: move to a better position, e.g. restarting the gateway... We don't reset the error here, as it wouldn't propagae to the backend properly
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
    func updateChargingSystemInformation() async throws {
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
    func handleError(err: Error) {
        self.sysError = err as? SystemError
        if let sysError = self.sysError {
            self.logger.error("\(String(describing: sysError.localizedDescription))", metadata: ["error": "\(sysError)"])
        }
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
