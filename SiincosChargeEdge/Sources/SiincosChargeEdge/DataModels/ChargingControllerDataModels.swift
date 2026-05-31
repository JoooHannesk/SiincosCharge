//
//  ChargingControllerDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.05.26.
//

import Foundation

struct ChargingSession {
    let sessionId: String // TODO: unique charging session id preferably based on starting date/time and charging point id
    let chargingPointId: String
    let startTime: Date
    var endTime: Date
    let user: String // ThingsBoard User
    var chargingSessionStatus: ChargingSessionStatus
}


enum ChargingSessionStatus {
    case running
    case finished
    case paused
}
