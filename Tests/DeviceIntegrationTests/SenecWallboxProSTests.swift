//
//  SenecWallboxProSTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 24.03.26.
//

import Testing
import Foundation
import ModbusSerial
@testable import SiincosChargeEdge


let chargerSenec: SenecWallboxProS11kW? = DeviceSupplierForTests.getSpecificCharger()


/// Senec Wallbox Pro S Device Tests
///
/// Specific device tests for the charger Wallbox Pro S from SENEC.
/// To run this test, a physical charger is required.
@Suite("Senec-Wallbox-Pro-S-Specific-Tests", .enabled(if: chargerSenec != nil ))
class SenecWallboxProSTests {
    var charger: SenecWallboxProS11kW

    init() throws {
        guard let chargerSenec else {
            try Test.cancel("SenecWallboxProS11kW not properly configured")
        }
        self.charger = chargerSenec
    }


    @Test("Test-Fallback-Current-Setpoint")
    func transferFallbackCurrentLimitSetpoints() async throws {
        let testValueFrame = [
            // (setpoint, expected)
            (4.0, 6.0),
            (6.0, 6.0),
            (8.5, 8.0),
            (10.0, 10.0),
            (16.0, 16.0),
            (18.0, 16.0),
        ]
        for testValue in testValueFrame {
            try await setSetpoint(to: Measurement(value: testValue.0, unit: UnitElectricCurrent.amperes), expected: Measurement(value: testValue.1, unit: UnitElectricCurrent.amperes))
        }

        // Set fallback (communication failure) current setpoint in EV charger
        func setSetpoint(to value: Measurement<UnitElectricCurrent>, expected: Measurement<UnitElectricCurrent>) async throws {
            let currentSetpoint = try await self.charger.setCommFailureMaxCurrent(to: value)
            print("Actual charger fallback current limit setpoint: \(currentSetpoint), Expected: \(expected) - Fullfilled: \(currentSetpoint == expected ? "✔" : "✘")")
            #expect(currentSetpoint == expected)
        }
    }


    @Test("Test-Power-Saving-Mode")
    func togglePowerSavingMode() async throws {
        let statusEn = try await self.charger.setPowerSavingState(to: .enabled)
        #expect(statusEn == .enabled)
        let statusDis = try await self.charger.setPowerSavingState(to: .disabled)
        #expect(statusDis == .disabled)
    }

    @Test("Test-Modbus-Watchdog-Timeout")
    func setModbusWatchdogTimeoutValues() async throws {
        let timeoutCollection: Array<UInt16> = [1000, 2000, 23255, 30000, 65535]
        for singleTimeout in timeoutCollection {
            let responsTimeout = try await self.charger.setModbusWatchdogTimeout(to: singleTimeout)
            #expect(responsTimeout == singleTimeout)
        }
    }

}
