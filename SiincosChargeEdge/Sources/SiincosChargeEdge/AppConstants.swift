//
//  AppConstants.swift
//  SiiSenseAgent
//
//  Created by Johannes Kinzig on 26.02.26.
//

import Foundation
import Logging

/// App Constants
///
/// App-wide static configuration parameters
enum AppConstants {

    /// App Version
    static let version = "0.0.4"

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
    static let maxRS485BusDevices: UInt8 = 10

    /// Absolute maximum allowed current per EV charger
    ///
    /// - Note: The system’s maximum allowable current is defined as the product of the absolute maximum per-charger current
    /// and the maximum number of configured chargers. This ensures that the load balancer cannot be configured to exceed
    /// defined current limits.
    static let maxChargerCurrentA: UInt8 = 32

    /// Failsafe EV charger current
    ///
    /// - Note: In case of a communication-loss between the controller and the chargers (or a single charger), the chargers require a
    /// failsafe current information. This is defined here and updated in the chargers cyclically.
    static let failsafeCurrentA: Double = 8

    /// Main run loop interval
    ///
    /// The main run loop executes at the interval defined here.
    ///
    /// - Note: An interval of 3 seconds offers a good balance between bus traffic, communication speed, and backend data transfer. The next run loop is scheduled 3 seconds after the previous one finishes executing. Therefore, one full cycle equals the execution time plus this interval.
    static let mainRunLoopCycle: TimeInterval = 3.0
}

