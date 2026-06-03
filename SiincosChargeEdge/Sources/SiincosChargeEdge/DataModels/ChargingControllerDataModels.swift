//
//  ChargingControllerDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.05.26.
//

import Foundation

/// Charging Session Data Model
struct ChargingSession: Hashable {

    /// Charging Session Id
    ///
    /// Unique charging session id based on starting date/time and charging point id
    let sessionId: String

    /// Charging Point Id
    let chargingPointId: UInt8

    /// Charging Session Start Time
    let startTime: Date

    /// Charging Session End time
    var endTime: Date

    /// User
    ///
    /// User who invoked the charging session
    let user: String

    /// Charging Session Status
    ///
    /// Either `.running`, `.finished`, `.paused`
    var chargingSessionStatus: ChargingSessionStatus

    /// Total Energy Consumption
    ///
    /// Total energy drawn from the charging point by the EV
    var totalEnergyConsumption: Measurement<UnitEnergy>

    /// Charging Current
    ///
    /// Charging current for the session set by the user or overriden by the
    /// charging managers load balancer
    var chargingCurrent: Measurement<UnitElectricCurrent>
}

/// Charging Session Status
enum ChargingSessionStatus {
    case running
    case finished
    case paused
}

/// Charging System Information Data Model
struct ChargingSystemInformation: Hashable, CustomStringConvertible {
    let appVersion: String
    let chargerModel: SupportedCharger
    let meterModel: SupportedPowerMeter
    let chargingPoints: UInt8
    let lineMaxCurrentA: UInt8

    var description: String {
        return """
            App Version: \(appVersion)
            Charger Model: \(chargerModel.rawValue)
            Power Meter Model: \(meterModel.rawValue)
            Charging Points: \(chargingPoints)
            Line Current (A): \(lineMaxCurrentA)
            """
    }
}
