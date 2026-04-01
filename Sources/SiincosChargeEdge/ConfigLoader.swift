//
//  ConfigLoader.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//


enum ConfigLoader {

    /// Load System Configuration
    ///
    /// Load system configuration from file and return a configuration instance.
    /// - Returns: System configuration as type ``SystemConfig``
    static func getSystemConfig() async -> SystemConfig? {
        let resourceLoader = JsonFileResourceLoader(logger: await FileLoggingConfiguration.shared.getLogger(for: AppConstants.mainLoggerLabel))
        return resourceLoader.load(fromFile: AppConstants.configFileLocation)
    }
}
