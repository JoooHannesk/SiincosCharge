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


/// Senec Wallbox Pro S Device Tests
///
/// Specific device tests for the charger Wallbox Pro S from SENEC.
/// To run this test, a physical charger is required.
class SenecWallboxProSTests {
    let unitId: UInt8
    let config: RTUClientConfiguration
    let modbusDevice: ModbusRTUClient
    let charger: SenecWallboxProS11kW
    static let devicePresent: Bool = true // TODO: skip if charger not available per config file

    init() {
        // TODO: make dynamic by loading the device based on config from file
        unitId = 1
        config = RTUClientConfiguration(
            serialConfiguration: SerialConfiguration(
                port: "/dev/tty.usbserial-AB0O6Z7W",
                baudRate: .b19200,
                parity: .even,
                stopBits: .one,
                dataBits: .eight,
                timeout: .seconds(3)
            ),
            retries: 3,
            errorRecovery: .exponentialBackoff(
                initialDelay: .milliseconds(500),
                maxDelay: .seconds(10)
            ),
            handleLocalEcho: false  // For RS-485 half-duplex adapters
        )
        modbusDevice = ModbusRTUClient(configuration: config)
        charger = SenecWallboxProS11kW(modbusDevice: modbusDevice, unitId: unitId)
    }

    @Test("Test-Fallback-Current-Setpoint", .enabled(if: Self.devicePresent))
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

        func setSetpoint(to value: Measurement<UnitElectricCurrent>, expected: Measurement<UnitElectricCurrent>) async throws {
            let currentSetpoint = try await self.charger.setCommFailureMaxCurrent(to: value)
            print("Actual charger fallback current limit setpoint: \(currentSetpoint), Expected: \(expected) - Fullfilled: \(currentSetpoint == expected ? "✔" : "✘")")
            #expect(currentSetpoint == expected)
        }
    }

}
