//
//  ChargingController.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.05.26.
//


actor ChargingController {

    let systemConfig: SystemConfig
    var backend: BackendController? = nil
    let chargingSystem: ChargingSystem? = nil

    //var error: SystemError? = nil

    /// Logger
    ///
    /// The application-wide main logger
    private let logger = ComponentSupplier.mainLogger

    init() async {
        systemConfig = Self.loadSystemConfig()
        backend = ThingsBoardBackend(chargingController: self)
        //chargingSystem = await ChargingSystem(config: systemConfig as DeviceConfig)
        print("Hello, I am SiincosChargeEdge charging controller!")
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
    /// Update charging system status information in backend. This includes all charging points
    /// with their respective properties.
    func updateChargingSystemStatus() {
        // TODO: implement
    }

    /// Update Application Status
    ///
    /// Update application information in backend. This includes: app version
    func updateApplicationInformation() {
        // TODO: implement
    }

    /// Load System Config
    ///
    /// Load system config from file.
    /// Abort on error, because the system is not operational without a valid config.
    static private func loadSystemConfig() -> SystemConfig {
        let systemConfig: SystemConfig
        do {
            systemConfig = try ComponentSupplier.getSystemConfig()
        } catch {
            let logger = ComponentSupplier.mainLogger
            logger.critical("Could not get system config.", metadata: ["error": "\(error)"])
            fatalError("Could not get system config.")
        }
        return systemConfig
    }

}
