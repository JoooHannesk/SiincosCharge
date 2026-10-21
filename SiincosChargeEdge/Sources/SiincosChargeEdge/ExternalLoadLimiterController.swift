//
//  ExternalLoadLimiter.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 15.10.26.
//

import Foundation


/// The external load limiter provides access to external load limiting signals
final class ExternalLoadLimiterController {
    
    private var extLoadLimiter: ExternalLoadLimiter
    
    var signal: LoadLimiterSignal {
        get throws {
            return try self.extLoadLimiter.loadLimitingSignal
        }
    }
    
    init(config: SystemConfig) {
        // Currently only a single load limiter implementation available
        // therefore using this one.
        // In future the settings file may decide about loading other available
        // load limitter implementations
        
        switch config.externalLoadLimiter {
        case .gpio:
            self.extLoadLimiter = ReComputerDIGPIOLoadLimiter(deratingMaxCurrent: config.externalLoadLimiterDeratingCurrent)
        }
    }
}
