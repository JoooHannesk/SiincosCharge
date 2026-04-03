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
    static func getSystemConfig() async -> SystemConfig? {
        let resourceLoader = JsonFileResourceLoader(logger: mainLogger)
        return resourceLoader.load(fromFile: AppConstants.configFileLocation)
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
        if deviceSetup.evChargers.isEmpty {
            mainLogger.error("No chargers configured!")
            throw SystemError.chargersMissing
        }
        if deviceSetup.powerMeters.isEmpty {
            mainLogger.error("No power meters configured!")
            throw SystemError.powerMetersMissing
        }
        return (deviceSetup.evChargers, deviceSetup.powerMeters)
    }

}
