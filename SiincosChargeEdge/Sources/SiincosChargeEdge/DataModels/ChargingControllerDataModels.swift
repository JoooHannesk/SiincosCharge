//
//  ChargingControllerDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.05.26.
//

import Foundation

/// Charging Session Data Model
///
/// Charging session data model which is maintained throughout an ongoing charging session
/// for a single charging point.
/// When charging has finished, this ``ChargingSession`` is used as a *Charging Session Receipt*
/// in the backend to maintaing history of all charging sessions.
struct ChargingSession: Hashable, Codable {

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
enum ChargingSessionStatus: String, Codable {
    case running
    case finished
    case paused
}

/// Charging Task
///
/// A charging task which is defined for each charging point
struct ChargingTask {
    let cpId: UInt8
    var chargingSession: ChargingSession?
}

/// Charging System Information Data Model
struct ChargingSystemInformation: Hashable, CustomStringConvertible, Codable {
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

/// Charging System Status Data Model
struct ChargingSystemStatus: Hashable, CustomStringConvertible, Codable {
    let cpId: UInt8
    let loadBalancedMaxCurrent: Measurement<UnitElectricCurrent>
    let chargingState: ChargerState
    let evState: EVState
    let chargingPermission: Status
    let chargingCurrentSetpoint: Measurement<UnitElectricCurrent>
    let meterReading: Measurement<UnitEnergy>
    let chargingCurrent: ElectricCurrent3PhaseGrid
    let chargingPower: ElectricPower3PhaseGrid
    let gridVoltage: ElectricVoltage3PhaseGrid

    var description: String {
        return """
            Charging Point ID: \(self.cpId)
            Load Balanced max. Current: \(loadBalancedMaxCurrent)
            Charging State: \(chargingState)
            EV State: \(evState)
            Charging: \(chargingPermission)
            Charging Current (Setpoint - A): \(chargingCurrentSetpoint)
            Meter Reading (kWh): \(meterReading)
            Charging Current (Real - A): \(chargingCurrent)
            Charging Power (Real - kW): \(chargingPower)
            Grid Voltage (Real – V/AC): \(gridVoltage)
            """
    }
}
