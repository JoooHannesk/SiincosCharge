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

    //var error: SystemError? = nil

    /// Logger
    ///
    /// The application-wide main logger
    private let logger = ComponentSupplier.mainLogger

    init() async {
        systemConfig = Self.loadSystemConfig()
        backend = ThingsBoardBackend(chargingController: self)
    }

    /// Start up
    ///
    /// Load required assets and log errors. In case of critical errors, shut down.
    func startup() async {
        print(LogMessages.welcomMsg)
        self.logger.info("\(LogMessages.welcomMsg)")
        do {
            try self.chargingSystem = await ChargingSystem(config: systemConfig as DeviceConfig)
            try self.backend?.startup()
        } catch {
            self.logger.critical("\(error.localizedDescription)", metadata: ["error": "\(error)"])
            self.shutdown()
        }
        self.updateChargingSystemInformation()
        await self.updateChargingSystemStatus()
    }

    /// Shutdown
    ///
    /// Shutdown gracefully
    func shutdown() {
        try? self.backend?.shutdown()
        ChargingController.shutdown()
    }

    /// Run
    ///
    /// Charging controller's main run loop
    func run() {
        // TODO: implement
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

    /// Update Charging System Status
    ///
    /// Update charging system status information in backend by
    /// collecting all charging point status information.
    func updateChargingSystemStatus() async {
        do {
            if let cps = await chargingSystem?.chargingPointContainer.chargingPoints {
                for (_, cp) in cps {
                    let chargingSystemStatus = ChargingSystemStatus(
                        cpId: await cp.cpId,
                        loadBalancedMaxCurrent: self.chargingSystem?.loadBalancedMaxCurrent ?? Measurement(value: 0.0, unit: UnitElectricCurrent.amperes),
                        chargingState: try await cp.chargingState,
                        evState: try await cp.evState,
                        chargingPermission: await cp.chargingPermission,
                        chargingCurrentSetpoint: try await cp.chargingCurrentSetpoint,
                        meterReading: try await cp.meterReading,
                        chargingCurrent: try await cp.chargingCurrent,
                        chargingPower: try await cp.chargingPower,
                        gridVoltage: try await cp.gridVoltage
                    )
                    self.backend?.updateChargingSystemStatus(with: chargingSystemStatus)
                    self.backend?.updateChargingSystemError(with: nil)
                }
            }
        } catch {
            let sysError = error as? SystemError
            self.backend?.updateChargingSystemError(with:sysError)
            logger.error("\(String(describing: error.localizedDescription))", metadata: ["error": "\(error)"])
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
    func updateChargingSystemInformation() {
        let chargingSystemInformation = ChargingSystemInformation(
            appVersion: AppConstants.version,
            chargerModel: self.systemConfig.chargerModel,
            meterModel: self.systemConfig.meterModel,
            chargingPoints: self.systemConfig.lineLength,
            lineMaxCurrentA: self.systemConfig.lineMaxCurrentA)
        self.logger.info("\(LogMessages.sysInfo)\n\(chargingSystemInformation.description)")
        self.backend?.updateChargingSystemInformation(with: chargingSystemInformation)
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
