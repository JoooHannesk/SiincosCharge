//
//  DataModelTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 03.07.26.
//

import Testing
import Foundation
@testable import SiincosChargeEdge


/// Data Model Tests
///
/// Test data model related functionality, e.g. conversion and encoding
@Suite("Data-Model-Tests", .serialized)
struct DataModelTests {

    @Test("Test-JSON-Encoding-For-ChargingSystemInformation-Data-Model")
    func testChargingSystemInformationJsonEncoding() throws {
        let csysInfo = ChargingSystemInformation(appVersion: "0.0.4",
                                                 chargerModel: .senecWallboxProS11kW,
                                                 meterModel: .janitzaSmartMeterB2331210J,
                                                 chargingPoints: 3,
                                                 lineMaxCurrent: Measurement(value: 16.0, unit: UnitElectricCurrent.amperes),
                                                 loadBalancedMaxCurrent: Measurement(value: 16.0, unit: UnitElectricCurrent.amperes),
                                                 sysError: nil)
        try #require(csysInfo.asJson != nil)
        if let jsonString = csysInfo.asJson {
            let jsonData = jsonString.data(using: .utf8)!
            let csysInfo2 = try JSONDecoder().decode(ChargingSystemInformation.self, from: jsonData)
            #expect(csysInfo == csysInfo2)
        }
    }

    @Test("Test-JSON-Encoding-For-ChargingSystemInformation-Data-Model-With-Error-Context")
    func testChargingSystemInformationJsonEncodingWithErrorContext() throws {
        let csysInfo = ChargingSystemInformation(appVersion: "0.0.4",
                                                 chargerModel: .senecWallboxProS11kW,
                                                 meterModel: .janitzaSmartMeterB2331210J,
                                                 chargingPoints: 3,
                                                 lineMaxCurrent: Measurement(value: 16.0, unit: UnitElectricCurrent.amperes),
                                                 loadBalancedMaxCurrent: Measurement(value: 16.0, unit: UnitElectricCurrent.amperes),
                                                 sysError: .chargersMissing)
        try #require(csysInfo.asJson != nil)
        if let jsonString = csysInfo.asJson {
            let jsonData = jsonString.data(using: .utf8)!
            let csysInfo2 = try JSONDecoder().decode(ChargingSystemInformation.self, from: jsonData)
            #expect(csysInfo == csysInfo2)
        }
    }

    @Test("Test-JSON-Encoding-For-ChargingSystemStatus-Data-Model")
    func testChargingSystemStatusJsonEncoding() throws {
        let csysStatus = ChargingPointStatus(cpId: 3,
                                            chargingState: .charging,
                                            evState: .pluggedIn,
                                            chargingPermission: .enabled,
                                            chargingCurrentSetpoint: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
                                            meterReading: Measurement(value: 523.4, unit: UnitEnergy.kilowattHours),
                                            chargingCurrent: ElectricCurrent3PhaseGrid(currentL1: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
                                                                                       currentL2: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
                                                                                       currentL3: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes)),
                                            chargingPower: ElectricPower3PhaseGrid(powerTotal: Measurement(value: 4.5, unit: UnitPower.kilowatts)),
                                            gridVoltage: ElectricVoltage3PhaseGrid(voltageL1: Measurement(value: 234.4, unit: UnitElectricPotentialDifference.volts),
                                                                                   voltageL2: Measurement(value: 224.8, unit: UnitElectricPotentialDifference.volts),
                                                                                   voltageL3: Measurement(value: 228.2, unit: UnitElectricPotentialDifference.volts)))
        try #require(csysStatus.asJson != nil)
        if let jsonString = csysStatus.asJson {
            let jsonData = jsonString.data(using: .utf8)!
            let csysStatus2 = try JSONDecoder().decode(ChargingPointStatus.self, from: jsonData)
            #expect(csysStatus == csysStatus2)
        }
    }

    @Test("Test-JSON-Serialization-For-ChargingSystemStatus-Data-Model")
    func testChargingSystemStatusJsonSerialization() throws {
        let csysStatus = ChargingPointStatus(cpId: 3,
                                            chargingState: .charging,
                                            evState: .pluggedIn,
                                            chargingPermission: .enabled,
                                            chargingCurrentSetpoint: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
                                            meterReading: Measurement(value: 523.4, unit: UnitEnergy.kilowattHours),
                                            chargingCurrent: ElectricCurrent3PhaseGrid(currentL1: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
                                                                                       currentL2: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
                                                                                       currentL3: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes)),
                                            chargingPower: ElectricPower3PhaseGrid(powerTotal: Measurement(value: 4.5, unit: UnitPower.kilowatts)),
                                            gridVoltage: ElectricVoltage3PhaseGrid(voltageL1: Measurement(value: 234.4, unit: UnitElectricPotentialDifference.volts),
                                                                                   voltageL2: Measurement(value: 224.8, unit: UnitElectricPotentialDifference.volts),
                                                                                   voltageL3: Measurement(value: 228.2, unit: UnitElectricPotentialDifference.volts)))
        try #require(csysStatus.asSerializedJson != nil)
        let csysStatusBack = try deserializeChargingPoint(from: csysStatus.asSerializedJson!)
        try #require(csysStatusBack != nil)
        #expect(csysStatusBack! == csysStatus)
    }

}
