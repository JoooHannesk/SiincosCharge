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

    /// Configuration file location
    static let configFileLocation = "/opt/SiincosChargeEdge/config.json"

    /// Logger configuration
    static let mainLoggerLabel = "SiincosChargeEdge"
    static let logFolderLocation = "/opt/SiincosChargeEdge/logs/"
}


/// MQTT Topics
///
/// Topics required to communicate with the MQTT server, e.g.
/// topic definitions for RPCs, attributes and telemetry
enum MQTTTopics {
    static let telemetryTopic = "v1/devices/me/telemetry"
    static let rpcTopic = "v1/devices/me/rpc/request/+"
    static let attributeTopic = "v1/devices/me/attributes"
}
