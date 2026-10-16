//
//  LoadLimiterDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 15.10.26.
//

import Foundation


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


protocol ExternalLoadLimiterSignalHandler {
    var loadLimitingSignal: LoadLimiterSignal { get throws }
}
