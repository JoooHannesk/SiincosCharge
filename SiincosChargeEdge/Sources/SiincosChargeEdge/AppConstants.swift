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

    /// Maximum RS485 line length (= maximum allowed devices on bus)
    ///
    /// - Note: As additional devices are added to the bus, overall traffic increases and the response time for each
    /// device grows accordingly. Since this app manages load balancing for the EV chargers, the time required to set the
    /// maximum allowed current per charger also rises. To maintain system stability and prevent unintended circuit breaker
    /// trips, this maximum bus length is defined here as a safeguard.
    static let maxRS485BusDevices: UInt8 = 5

    /// Absolute maximum allowed current per EV charger
    ///
    /// - Note: The system’s maximum allowable current is defined as the product of the absolute maximum per-charger current and the maximum number of configured chargers. This ensures that the load balancer cannot be configured to exceed defined current limits.
    static let maxChargerCurrentA: UInt8 = 32
}
