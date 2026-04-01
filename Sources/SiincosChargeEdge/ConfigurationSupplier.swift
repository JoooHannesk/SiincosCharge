//
//  ConfigLoader.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//


enum ConfigurationSupplier {

    static let mainLogger = FileLoggingConfiguration.shared.getLogger(for: AppConstants.mainLoggerLabel)

    /// Load System Configuration
    ///
    /// Load system configuration from file and return a configuration instance.
    /// - Returns: System configuration as type ``SystemConfig``
    static func getSystemConfig() async -> SystemConfig? {
        let resourceLoader = JsonFileResourceLoader(logger: mainLogger)
        return resourceLoader.load(fromFile: AppConstants.configFileLocation)
    }

//    static func getDevices(for config: SystemConfig) -> (Array<EVCharger>, Array<PowerMeter>) {
//
//    }

}
