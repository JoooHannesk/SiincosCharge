//
//  ComponentSupplier.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//


enum ComponentSupplier {

    static let mainLogger = FileLoggingConfiguration.shared.getLogger(for: AppConstants.mainLoggerLabel)

    /// Load System Configuration
    ///
    /// Load system configuration from file and return a configuration instance.
    /// - Returns: System configuration as type ``SystemConfig``
    static func getSystemConfig() throws(SystemError) -> SystemConfig {
        let resourceLoader = JsonFileResourceLoader()
        let path = AppConstants.configFileLocation
        if let systemConfig: SystemConfig = resourceLoader.load(fromFile: path)
        {
            mainLogger.info("Loaded system configuration from \(path)")
            return systemConfig
        } else {
            mainLogger.critical(
                "System configuration file not found or not readable at path: \(path)",
                metadata: [
                    "error":
                        "\(String(describing: SystemError.configFileNotFound.localizedDescription))"
                ]
            )
            throw SystemError.configFileNotFound
        }
    }


    /// Setup Devices
    ///
    /// Setup ev chargers and power meters
    /// - Parameter config: system config ``SystemConfig``
    /// - Returns: Tuple containing two arrays, the first holding the ``EVCharger``s and the
    /// second one holding the ``PowerMeter``s
    /// - Throws: ``SystemError`` in case there are no ``EVCharger`` s or ``PowerMeter``s configured
    static func getDevices(for config: SystemConfig) throws(SystemError) -> (Array<EVCharger>, Array<PowerMeter>) {
        let deviceSetup = DeviceSetup(config: config)
        mainLogger.info("Configured devices - EVChargers: \(deviceSetup.evChargers.count), PowerMeters: \(deviceSetup.powerMeters.count)")
        if deviceSetup.evChargers.isEmpty {
            mainLogger.error("No EV chargers configured.",  metadata: ["error": "\(String(describing: SystemError.chargersMissing.localizedDescription))"])
            throw SystemError.chargersMissing
        }
        if deviceSetup.powerMeters.isEmpty {
            mainLogger.error("No power meters configured.", metadata: ["error": "\(String(describing: SystemError.powerMetersMissing.localizedDescription))"])
            throw SystemError.powerMetersMissing
        }
        mainLogger.info("Device setup completed successfully. Returning \(deviceSetup.evChargers.count) EV Chargers and \(deviceSetup.powerMeters.count) Power Meters")
        return (deviceSetup.evChargers, deviceSetup.powerMeters)
    }
}

