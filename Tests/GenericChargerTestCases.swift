//
//  DeviceIntegrationTestsGenericCharger.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 24.03.26.
//

import Testing
import Foundation
import ModbusSerial
@testable import SiincosChargeEdge


/// Generic Charger Device Test Cases
///
/// Generic tests for the car chargers
/// To run this test, a physical charger is required.
class GenericChargerTestCases {

    let unitId: UInt8
    let config: RTUClientConfiguration
    let modbusDevice: ModbusRTUClient
    let charger: CarCharger

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
        charger = SenecWallboxProS(modbusDevice: modbusDevice, unitId: unitId)
    }

    @Test("Get-Charging-State")
    func getChargingState() async throws {
        let state = try await self.charger.getChargingState()
        #expect(state != .unknown)
        print("Charger State: \(state)")
    }

    @Test("Get-Internal-Temperature")
    func getInternalTemperature() async throws {
        let temperature = try await self.charger.getInternalTemperature()
        let tempLow = Measurement(value: -25.0, unit: UnitTemperature.celsius)
        let tempHigh = Measurement(value: 40.0, unit: UnitTemperature.celsius)
        print("Charger internal temperature: \(temperature)")
        #expect(temperature > tempLow && temperature < tempHigh)
    }

    @Test("Get-Hardware-Current-Limits")
    func getHardwareCurrentLimits() async throws {
        let currLimits = try await self.charger.getHardwareCurrentLimits()
        let currLow = Measurement(value: 6.0, unit: UnitElectricCurrent.amperes) // Lower limits won't be accepted by the vehicles, as they'd result in the vehicle rejectes charging
        let currHigh = Measurement(value: 16.0, unit: UnitElectricCurrent.amperes)
        print("Charger hardware current limits: \(currLimits)")
        #expect(currLow == currLimits.minimal && currHigh >= currLimits.maximal)
    }

    @Test("Transfer-Current-Limit-Setpoints")
    func transferCurrentLimitSetpoints() async throws {
        let testValueFrame = [
            // (setpoint, expected)
            (0.0, 6.0),
            (4.0, 6.0),
            (6.0, 6.0),
            (8.0, 8.0),
            (8.7, 8.0),
            (10.0, 10.0),
            (14.0, 14.0),
            (16.0, 16.0),
            (18.0, 16.0),
            (18.7, 16.0),
        ]
        for testValue in testValueFrame {
            try await setSetpoint(to: Measurement(value: testValue.0, unit: UnitElectricCurrent.amperes), expected: Measurement(value: testValue.1, unit: UnitElectricCurrent.amperes))
        }

        func setSetpoint(to value: Measurement<UnitElectricCurrent>, expected: Measurement<UnitElectricCurrent>) async throws {
            let currentSetpoint = try await self.charger.setMaxCurrentLimitSetpoint(to: value)
            print("Actual charger current limit setpoint: \(currentSetpoint), Expected: \(expected) - Fullfilled: \(currentSetpoint == expected ? "✔" : "✘")")
            #expect(currentSetpoint == expected)
        }
    }

    @Test("Get-Hardware-Lock-State")
    func getHardwareLockState() async throws {
        let state = try await self.charger.getHardwareLockState()
        print("Actual charger hardware lock state: \(state)")
        #expect(state == .unlocked)
    }
}
