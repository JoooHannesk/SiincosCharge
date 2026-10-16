//
//  ExternalLoadLimiter.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 15.10.26.
//

import Foundation


/// The external load limiter provides access to external load limiting signals
final class ExternalLoadLimiter {
    
    var signal: LoadLimiterSignal {
        .normalOperation
    }
    
    init(config: SystemConfig) {
        
    }
}
