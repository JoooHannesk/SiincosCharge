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

    /// Charging Point ID
    ///
    /// Canonical charging-point identifier used across app/backend and the physical site.
    /// Mirrors the charger's Modbus unit ID for simplicity reasons.
    let cpId: UInt8

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

    /// Charging Current Setpoint
    ///
    /// Charging current for the session set by the user
    var chargingCurrentSetpoint: Measurement<UnitElectricCurrent>
}

/// Charging Session Status
enum ChargingSessionStatus: String, Codable {
    case running
    case finished
    case paused
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

    /// Return object as JSON
    ///
    /// Convert object to JSON and return as string. This functionality is required
    /// when passing data to third-party systems, e.g. cloud backends.
    /// - Note: If conversion fails, `nil` is returned.
    var asJson: String? {
        var asJson: String? = nil
        let encoder = JSONEncoder()
        //encoder.outputFormatting = .prettyPrinted
        let data = try? encoder.encode(self)
        if let data {
            asJson = String(data: data, encoding: .utf8)
        }
        return asJson
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
