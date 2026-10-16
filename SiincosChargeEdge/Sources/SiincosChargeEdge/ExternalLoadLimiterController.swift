//
//  ExternalLoadLimiter.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 15.10.26.
//

import Foundation


/// The external load limiter provides access to external load limiting signals
final class ExternalLoadLimiterController {
    
    private var extLoadLimiter: ExternalLoadLimiter?
    
    var signal: LoadLimiterSignal {
        get throws {
            return .normalOperation
        }
    }
    
    init(config: SystemConfig) {
        
    }
}
