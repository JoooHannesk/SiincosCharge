//
//  Untitled.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 13.05.26.
//

import Testing
import Foundation
import ModbusSerial
@testable import SiincosChargeEdge


let powerMeterJanitza: JanitzaSmartMeterB2331210J? = DeviceSupplierForTests.getSpecificPowerMeter()


/// Janitza Smart Meter B23-312-10J Device Tests
///
/// Specific device tests for the charger Wallbox Pro S from SENEC.
/// To run this test, a physical charger is required.
///
/// - Note: These tests are unnecessary, as test cases already covered by ``GenericPowerMeterTests``
@Suite("Janitza-SmartMeter-B23-312-10J-Specific-Tests", .enabled(if: powerMeterJanitza != nil ))
class JanitzaSmartMeterB2331210JTests {
    var powerMeter: JanitzaSmartMeterB2331210J

    init() throws {
        guard let powerMeterJanitza else {
            try Test.cancel("SenecWallboxProS11kW not properly configured.")
        }
        self.powerMeter = powerMeterJanitza
    }

    @Test("Test-Get-Current-Drawn")
    func getCurrentDrawn() async throws {
        let currentDrawn = try await powerMeter.getElectricCurrent()
        print(currentDrawn)
    }

    @Test("Test-Get-Grid-Voltage")
    func getGridVoltage() async throws {
        let gridVoltage = try await powerMeter.getGridVoltage()
        print(gridVoltage)
    }

    @Test("Test-Get-Electric-Power")
    func getElectricPower() async throws {
        let electricPower = try await powerMeter.getElectricPower()
        print(electricPower)
    }

    @Test("Test-Get-Electric-Energy")
    func getElectricEnergySinceInstallation() async throws {
        let energy = try await powerMeter.getElectricEnergy()
        print(energy)
    }
}
