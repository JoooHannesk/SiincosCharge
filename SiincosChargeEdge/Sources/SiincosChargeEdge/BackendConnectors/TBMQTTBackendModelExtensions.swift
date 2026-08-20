//
//  TBMQTTBackendModelExtensions.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 07.07.26.
//

import Foundation
import SiincosChargeDataModels


/// Charging System Information Extension
///
/// Custom model extension for ThingsBoard/MQTT backend
extension ChargingSystemInformation: JsonStringConvertible {

    enum CodingKeys: String, CodingKey {
        case systemId, appVersion, chargerModel, meterModel, chargingPoints, chargingPointsCharging, lineMaxCurrentA, loadBalancedMaxCurrentA, sysError
    }

    /// Encodes `ChargingSystemInformation` to a flat JSON structure.
    ///
    /// - Note: The `lineMaxCurrent` property is encoded as a single numeric value using the key `lineMaxCurrentA` (amperes only), for interoperability with flat-data systems like MQTT/ThingsBoard. Same applies to `loadBalancedMaxCurrent`.
    /// - Throws: An error if any value fails to encode.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(systemId, forKey: .systemId)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(chargerModel, forKey: .chargerModel)
        try container.encode(meterModel, forKey: .meterModel)
        try container.encode(chargingPoints, forKey: .chargingPoints)
        try container.encode(chargingPointsCharging, forKey: .chargingPointsCharging)
        try container.encode(lineMaxCurrent.converted(to: .amperes).value, forKey: .lineMaxCurrentA)
        try container.encode(loadBalancedMaxCurrent.converted(to: .amperes).value, forKey: .loadBalancedMaxCurrentA)
        try container.encode(sysError?.rawValue ?? "", forKey: .sysError)
    }

    /// Decodes ChargingSystemInformation from a flat JSON structure.
    ///
    /// - Note: The `lineMaxCurrentA` key is decoded as a numeric value in amperes and reconstructed as a `Measurement<UnitElectricCurrent>`. Same applies to `loadBalancedMaxCurrentA`
    /// - Throws: An error if any value fails to decode or is missing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.systemId = try container.decode(String.self, forKey: .systemId)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.chargerModel = try container.decode(SupportedCharger.self, forKey: .chargerModel)
        self.meterModel = try container.decode(SupportedPowerMeter.self, forKey: .meterModel)
        self.chargingPoints = try container.decode(UInt8.self, forKey: .chargingPoints)
        self.chargingPointsCharging = try container.decode(UInt8.self, forKey: .chargingPointsCharging)
        let lmca = try container.decode(Double.self, forKey: .lineMaxCurrentA)
        self.lineMaxCurrent = Measurement(value: lmca, unit: UnitElectricCurrent.amperes)
        let lbmca = try container.decode(Double.self, forKey: .loadBalancedMaxCurrentA)
        self.loadBalancedMaxCurrent = Measurement(value: lbmca, unit: UnitElectricCurrent.amperes)
        let errorString = try container.decode(String.self, forKey: .sysError)
        self.sysError = errorString.isEmpty ? nil : SystemError(rawValue: errorString)
    }
}

/// Charging Point Status Extension
///
/// Custom model extension for ThingsBoard/MQTT backend
extension ChargingPointStatus: JsonStringConvertible, SerializedJsonStringConvertible {

    enum CodingKeys: String, CodingKey {
        case cpId
        case chargerTemperatureC
        case chargingState
        case evState
        case chargingPermission
        case chargingCurrentSetpointA
        case meterReadingkWh
        case chargingCurrentL1A, chargingCurrentL2A, chargingCurrentL3A, chargingCurrentAvgA
        case chargingPowerL1kW, chargingPowerL2kW, chargingPowerL3kW, chargingPowerTotalkW
        case gridVoltageL1N, gridVoltageL2N, gridVoltageL3N
    }

    /// Encodes `ChargingPointStatus` to a flat JSON structure.
    ///
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cpId, forKey: .cpId)
        try container.encode(chargerTemperature.converted(to: UnitTemperature.celsius).value, forKey: .chargerTemperatureC)
        try container.encode(chargingState.rawValue, forKey: .chargingState)
        try container.encode(evState.rawValue, forKey: .evState)
        try container.encode(chargingPermission.rawValue, forKey: .chargingPermission)
        try container.encode(chargingCurrentSetpoint.converted(to: .amperes).value, forKey: .chargingCurrentSetpointA)
        try container.encode(meterReading.converted(to: .kilowattHours).value, forKey: .meterReadingkWh)
        try container.encode(chargingCurrent.currentL1?.converted(to: .amperes).value, forKey: .chargingCurrentL1A)
        try container.encode(chargingCurrent.currentL2?.converted(to: .amperes).value, forKey: .chargingCurrentL2A)
        try container.encode(chargingCurrent.currentL3?.converted(to: .amperes).value, forKey: .chargingCurrentL3A)
        try container.encode(chargingCurrent.currentAverage.converted(to: .amperes).value, forKey: .chargingCurrentAvgA)
        try container.encode(chargingPower.powerL1?.converted(to: .kilowatts).value, forKey: .chargingPowerL1kW)
        try container.encode(chargingPower.powerL2?.converted(to: .kilowatts).value, forKey: .chargingPowerL2kW)
        try container.encode(chargingPower.powerL3?.converted(to: .kilowatts).value, forKey: .chargingPowerL3kW)
        try container.encode(chargingPower.powerTotal.converted(to: .kilowatts).value, forKey: .chargingPowerTotalkW)
        try container.encode(gridVoltage.voltageL1?.value, forKey: .gridVoltageL1N)
        try container.encode(gridVoltage.voltageL2?.value, forKey: .gridVoltageL2N)
        try container.encode(gridVoltage.voltageL3?.value, forKey: .gridVoltageL3N)
    }

    /// Decodes `ChargingPointStatus` from a flat JSON structure.
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cpId = try container.decode(UInt8.self, forKey: .cpId)
        self.chargerTemperature = Measurement(value: try container.decode(Double.self, forKey: .chargerTemperatureC), unit: UnitTemperature.celsius)
        self.chargingState = ChargerState(rawValue: try container.decode(String.self, forKey: .chargingState)) ?? .unknown
        self.evState = EVState(rawValue: try container.decode(String.self, forKey: .evState)) ?? .unknown
        self.chargingPermission = Status(rawValue: try container.decode(UInt8.self, forKey: .chargingPermission)) ?? .unknown
        self.chargingCurrentSetpoint = Measurement(value: try container.decode(Double.self, forKey: .chargingCurrentSetpointA), unit: .amperes)
        self.meterReading = Measurement(value: try container.decode(Double.self, forKey: .meterReadingkWh), unit: .kilowattHours)
        let currentL1 = try container.decodeIfPresent(Double.self, forKey: .chargingCurrentL1A).map { Measurement(value: $0, unit: UnitElectricCurrent.amperes) }
        let currentL2 = try container.decodeIfPresent(Double.self, forKey: .chargingCurrentL2A).map { Measurement(value: $0, unit: UnitElectricCurrent.amperes) }
        let currentL3 = try container.decodeIfPresent(Double.self, forKey: .chargingCurrentL3A).map { Measurement(value: $0, unit: UnitElectricCurrent.amperes) }
        self.chargingCurrent = ElectricCurrent3PhaseGrid(
            currentL1: currentL1,
            currentL2: currentL2,
            currentL3: currentL3
        )
        let powerL1 = try container.decodeIfPresent(Double.self, forKey: .chargingPowerL1kW).map { Measurement(value: $0, unit: UnitPower.kilowatts) }
        let powerL2 = try container.decodeIfPresent(Double.self, forKey: .chargingPowerL2kW).map { Measurement(value: $0, unit: UnitPower.kilowatts) }
        let powerL3 = try container.decodeIfPresent(Double.self, forKey: .chargingPowerL3kW).map { Measurement(value: $0, unit: UnitPower.kilowatts) }
        let powerTotal = Measurement(value: try container.decode(Double.self, forKey: .chargingPowerTotalkW), unit: UnitPower.kilowatts)
        self.chargingPower = ElectricPower3PhaseGrid(
            powerL1: powerL1,
            powerL2: powerL2,
            powerL3: powerL3,
            powerTotal: powerTotal
        )
        let voltageL1 = try container.decodeIfPresent(Double.self, forKey: .gridVoltageL1N).map { Measurement(value: $0, unit: UnitElectricPotentialDifference.volts) }
        let voltageL2 = try container.decodeIfPresent(Double.self, forKey: .gridVoltageL2N).map { Measurement(value: $0, unit: UnitElectricPotentialDifference.volts) }
        let voltageL3 = try container.decodeIfPresent(Double.self, forKey: .gridVoltageL3N).map { Measurement(value: $0, unit: UnitElectricPotentialDifference.volts) }
        self.gridVoltage = ElectricVoltage3PhaseGrid(
            voltageL1: voltageL1,
            voltageL2: voltageL2,
            voltageL3: voltageL3
        )
    }
}

/// Charging Session Extension
///
/// Custom model extension for ThingsBoard/MQTT backend
extension ChargingSession: JsonStringConvertible, SerializedJsonStringConvertible {

    enum CodingKeys: String, CodingKey {
        case sessionId
        case cpId
        case startTime
        case endTime
        case meterReadingStartkWh
        case meterReadingEndkWh
        case userName
        case status
        case totalEnergyConsumedkWh
        case totalChargingDuration
        case chargingCurrentSetpointA
    }

    /// Encode to a flat json string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(cpId, forKey: .cpId)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(meterReadingStart?.converted(to: .kilowattHours).value, forKey: .meterReadingStartkWh)
        try container.encode(meterReadingEnd?.converted(to: .kilowattHours).value, forKey: .meterReadingEndkWh)
        try container.encode(userName, forKey: .userName)
        try container.encode(status, forKey: .status)
        try container.encode(totalEnergyConsumed?.converted(to: .kilowattHours).value, forKey: .totalEnergyConsumedkWh)
        try container.encode(totalChargingDuration, forKey: .totalChargingDuration)
        try container.encode(chargingCurrentSetpoint.converted(to: .amperes).value, forKey: .chargingCurrentSetpointA)
    }

    /// Decode from a flat json string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        self.cpId = try container.decode(UInt8.self, forKey: .cpId)
        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        if let meterReadingStart = try container.decodeIfPresent(Double.self, forKey: .meterReadingStartkWh) {
            self.meterReadingStart = Measurement(value: meterReadingStart, unit: .kilowattHours)
        }
        if let meterReadingEnd = try container.decodeIfPresent(Double.self, forKey: .meterReadingEndkWh) {
            self.meterReadingEnd = Measurement(value: meterReadingEnd, unit: .kilowattHours)
        }
        userName = try container.decode(String.self, forKey: .userName)
        status = try container.decode(ChargingSessionStatus.self, forKey: .status)
        self.chargingCurrentSetpoint = Measurement(value: try container.decode(Double.self, forKey: .chargingCurrentSetpointA), unit: .amperes)

    }


}
