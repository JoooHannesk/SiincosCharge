//
//  ChargingControllerDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.05.26.
//

import Foundation
import SiincosChargeDataModels

/// Charging Session Data Model
///
/// Charging session data model which is maintained throughout an ongoing charging session
/// for a single charging point.
/// When charging has finished, this ``ChargingSession`` is used as a *Charging Session Receipt*
/// in the backend to maintaing history of all charging sessions.
struct ChargingSession: Hashable, CustomStringConvertible, Codable {

    /// Charging Session Id
    ///
    /// Unique charging session id based on starting date/time and charging point id
    var sessionId: String?

    /// Charging Point ID
    ///
    /// Canonical charging-point identifier used across app/backend and the physical site.
    /// Mirrors the charger's Modbus unit ID for simplicity reasons.
    let cpId: UInt8

    /// Charging Session Start Time
    var startTime: Date?

    /// Charging Session End time
    var endTime: Date?

    /// Power meter reading at charging session start time
    var meterReadingStart: Measurement<UnitEnergy>?

    /// Power meter reading at charging session end time
    var meterReadingEnd: Measurement<UnitEnergy>?

    /// User
    ///
    /// User that invoked the charging session. Treated as the session
    /// owner throughout a whole session lifecycle.
    let userName: String

    /// Charging Session Status
    ///
    /// Either `.running`, `.finished`, `.paused`, `.scheduled`
    var status: ChargingSessionStatus

    /// Total Energy Consumed
    ///
    /// Total energy drawn from the charging point by the EV
    var totalEnergyConsumed: Measurement<UnitEnergy>? {
        guard let meterEnd = self.meterReadingEnd, let meterStart = self.meterReadingStart else {
            return nil
        }
        let energyConsumed = meterEnd.converted(to: .kilowattHours).value - meterStart.converted(to: .kilowattHours).value
        return Measurement(value: energyConsumed, unit: .kilowattHours)
    }

    /// Total Charging Duration
    var totalChargingDuration: TimeInterval? {
        guard let startTime = self.startTime, let endTime = self.endTime else {
            return nil
        }
        return endTime.timeIntervalSince(startTime)
    }

    /// Charging Current Setpoint
    ///
    /// Charging current for the session set by the user
    let chargingCurrentSetpoint: Measurement<UnitElectricCurrent>

    /// Stringconvertible description
    var description: String {
        return """
            Session ID: \(sessionId ?? "<n/a>"),
            Charging Point: \(cpId),
            Start Timestamp: \(startTime, default: "<n/a>"),
            End Timestamp: \(endTime, default: "<n/a>"),
            Meter Reading Start (kWh): \(meterReadingStart, default: "<n/a>"),
            Meter Reading End (kWh): \(meterReadingEnd, default: "<n/a>"),
            User: \(userName),
            Status: \(status),
            Total Energy Consumption: \(totalEnergyConsumed, default: "<n/a>"),
            Total Charging Duration: \(totalChargingDuration, default: "<n/a>"),
            Charging Current Setpoint: \(chargingCurrentSetpoint)
            """
    }

    init(
        sessionId: String? = nil,
        cpId: UInt8,
        startTime: Date? = nil,
        endTime: Date? = nil,
        meterReadingStart: Measurement<UnitEnergy>? = nil,
        meterReadingEnd: Measurement<UnitEnergy>? = nil,
        userName: String,
        chargingSessionStatus: ChargingSessionStatus,
        chargingCurrentSetpoint: Measurement<UnitElectricCurrent>
    ) {
        self.sessionId = sessionId
        self.cpId = cpId
        self.startTime = startTime
        self.endTime = endTime
        self.meterReadingStart = meterReadingStart
        self.meterReadingEnd = meterReadingEnd
        self.userName = userName
        self.status = chargingSessionStatus
        self.chargingCurrentSetpoint = chargingCurrentSetpoint
    }

    /// Start charging
    ///
    /// Set `sessionId`, `startTime`, `meterReadingStart` and `status` to `.running`.
    ///
    /// - Parameters:
    ///   - systemId: `systemId` from config, required to generate `sessionId`.
    ///   - startTime: Datetime the charging session starts
    ///   - meterReading: Current meter reading
    mutating func startCharging(systemId: String, startTime: Date, meterReading: Measurement<UnitEnergy>) {
        self.sessionId = "\(systemId)-\(DataModelsHelpers.getDateTimeString(from: startTime))-\(cpId)"
        self.startTime = startTime
        self.meterReadingStart = meterReading
        self.status = .running
    }

    /// Schedule charging
    ///
    /// Set `sessionId`, `startTime`, `endTime`,  and `status` to `.scheduled`.
    ///
    /// - Parameters:
    ///   - systemId: `systemId` from config, required to generate `sessionId`.
    ///   - startTime: Datetime the charging session starts, should be in the future
    ///   - endTime: Datetime the charging session ends, should be in the future
    mutating func scheduleCharging(systemId: String, startTime: Date, endTime: Date) {
        self.sessionId = "\(systemId)-\(DataModelsHelpers.getDateTimeString(from: startTime))-\(cpId)"
        self.startTime = startTime
        self.endTime = endTime
        self.status = .scheduled
    }

    /// Resume charging
    ///
    /// Set `status` to `.running`.
    mutating func resumeCharging() {
        self.status = .running
    }

    /// Pause charging
    ///
    /// Set `status` to `.paused`.
    mutating func pauseCharging() {
        if self.status == .running {
            self.status = .paused
        }
    }

    /// Finish Charging
    ///
    /// Set `status` to `.finished`, set `endTime` to current datetime, `meterReadingEnd` to current meter
    /// reading and based on this calculate `totalEnergyConsumed`
    ///
    /// - Parameters:
    ///   - endTime: Session ending datetime
    ///   - meterReading: Meter reading for this exact datetime
    mutating func finishCharging(endTime: Date, meterReading: Measurement<UnitEnergy>) {
        self.status = .finished
        self.endTime = endTime
        self.meterReadingEnd = meterReading
    }

    /// Update Meter Reading
    ///
    /// Update the meter reading to continuously track energy consumption during this session.
    mutating func update(with meterReading: Measurement<UnitEnergy>) {
        self.meterReadingEnd = meterReading
    }
}

/// Charging Session Status
///
/// These cases describe the charging session status:
/// - running: a charging session is running, the ev charger is unlocked and the ev is ready to request power
/// - finished: a charging session is finished, mainly used in charging session receipts
/// - paused: a charging session is paused (by the charging session owner) and waits for being resumed
/// - scheduled: a charging session is scheduled for the future and is waiting to start (when scheduled datetime is reached)
enum ChargingSessionStatus: String, Codable {
    case running
    case finished
    case paused
    case scheduled
}

/// Charging System Information Data Model
struct ChargingSystemInformation: Hashable, CustomStringConvertible, Codable {
    let systemId: String
    let appVersion: String
    let chargerModel: SupportedCharger
    let meterModel: SupportedPowerMeter
    let chargingPoints: UInt8
    let chargingPointsCharging: UInt8
    let lineMaxCurrent: Measurement<UnitElectricCurrent>
    let loadBalancedMaxCurrent: Measurement<UnitElectricCurrent>
    let sysError: SystemError?

    var description: String {
        return """
            System ID: \(systemId)
            App Version: \(appVersion)
            Charger Model: \(chargerModel.rawValue)
            Power Meter Model: \(meterModel.rawValue)
            Charging Points: \(chargingPoints)
            Charging Points charging: \(chargingPointsCharging)
            Line Current (A): \(lineMaxCurrent)
            Load Balanced max. Current (A): \(loadBalancedMaxCurrent)
            Error: \(String(describing: sysError))
            """
    }
}

/// Charging Point Status Data Model
struct ChargingPointStatus: Hashable, CustomStringConvertible, Codable, Sendable {
    let cpId: UInt8
    let chargerTemperature: Measurement<UnitTemperature>
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
            Charger Temperature: \(self.chargerTemperature)
            Charging State: \(self.chargingState)
            EV State: \(self.evState)
            Charging: \(self.chargingPermission)
            Charging Current (Setpoint - A): \(self.chargingCurrentSetpoint)
            Meter Reading (kWh): \(self.meterReading)
            Charging Current (Real - A): \(self.chargingCurrent)
            Charging Power (Real - kW): \(self.chargingPower)
            Grid Voltage (Real – V/AC): \(self.gridVoltage)
            """
    }
}
