//
//  AppConstants.swift
//  SiiSenseAgent
//
//  Created by Johannes Kinzig on 26.02.26.
//

import Logging

/// App Constants
///
/// App-wide static configuration parameters
enum AppConstants {

    /// App Version
    static let version = "0.0.1"

    /// Configuration file location
    static let configFileLocation = "/opt/SiincosChargeEdge/Assets/config.json"

    /// Logger configuration
    static let mainLoggerLabel = "SiincosChargeEdge"
    static let logFolderLocation = "/opt/SiincosChargeEdge/Logs/"
}
