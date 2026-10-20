//
//  LoadLimiterDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 15.10.26.
//

import Foundation

/// System supported external load limiter types
enum ExternalLoadLimiterType: String, Codable {
    /// External load limiting signal is transmitted into the system using GPIOs
    case gpio
}

/// The load limiter signal provides information about
/// the external load limiting type.
enum LoadLimiterSignal: Equatable {
    
    /// Normal system operation, no cutoff or derating required
    case normalOperation
    
    /// System cutoff required, current drawn should not exceed 0
    /// (only standby current allowed)
    case cutOff
    
    /// System derating required, current drawn should not exceed `deratedMaxCurrent`
    case derating(Measurement<UnitElectricCurrent>?)
}


protocol ExternalLoadLimiter {
    var loadLimitingSignal: LoadLimiterSignal { get throws }
}
