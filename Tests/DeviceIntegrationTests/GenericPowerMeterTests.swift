//
//  GenericPowerMeterTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 13.04.26.
//

import Testing
import Foundation
import ModbusSerial
@testable import SiincosChargeEdge


/// Generic Power Meter Device Tests
///
/// Generic tests for the power meters
/// To run this test, a physical power meter or charger with integrated power meter is required.
class GenericPowerMeterTests {

    let powerMeter: PowerMeter

    init() throws {

        let systemConfig = try ComponentSupplier.getSystemConfig()
        let devices = try ComponentSupplier.getDevices(for: systemConfig)

        // Take the first power meter on the bus
        guard let powerMeter = devices.powerMeters.first else {
            throw SystemError.powerMetersMissing
        }
        self.powerMeter = powerMeter
    }

    @Test("Get-Electric-Current")
    func getElectricCurrentDrawn() async throws {
        let current = try await self.powerMeter.getElectricCurrent()
        print("Currently drawn current: \(current)")
        #expect(current.currentL1!.value >= 0.0 && current.currentL2!.value >= 0.0 && current.currentL3!.value >= 0.0)
    }

    @Test("Get-Electric-Grid-Voltage")
    func getElectricGridVoltage() async throws {
        let gridVoltage = try await self.powerMeter.getGridVoltage()
        print("Current grid voltage: \(gridVoltage)")
        #expect(gridVoltage.voltageL1!.value > 200 && gridVoltage.voltageL2!.value > 200 && gridVoltage.voltageL3!.value > 200)
    }

    @Test("Get-Electric-Power")
    func getElectricPower() async throws {
        let power = try await self.powerMeter.getElectricPower()
        print("Currently drawn power: \(power)")
        #expect(power.powerL1!.value >= 0.0 && power.powerL2!.value >= 0.0 && power.powerL3!.value >= 0.0 && power.powerTotal.value >= 0.0)
    }

    @Test("Get-Electric-Energy-Since-Installation")
    func getTotalEnergyConsumedSinceInstallation() async throws {
        let energy = try await self.powerMeter.getElectricEnergy()
        print("Energy since installation: \(energy)")
        #expect(energy.value >= 0.0)
    }
}
