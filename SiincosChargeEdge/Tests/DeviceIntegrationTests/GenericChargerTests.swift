//
//  GenericChargerTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 24.03.26.
//

import Testing
import Foundation
import ModbusSerial
@testable import SiincosChargeEdge


/// Generic Charger Device Tests
///
/// Generic tests for the EV chargers.
/// This test can (and should) be used as an integration test for compatible chargers. Therefore, a
/// physical connected charger is required.
///
/// - Note: As the tests involve device communication via ModbusRTU/TCP, they have to be serialized.
/// Both, ModbusTCP and ModbusRTU are not designed to handle multiple connections in parallel.
@Suite("Generic-Charger-Tests", .serialized)
class GenericChargerTests {

    let charger: EVCharger

    init() throws {

        let systemConfig = try ComponentSupplier.getSystemConfig()
        let devices = try ComponentSupplier.getDevices(for: systemConfig)

        // Take the first charger on the bus
        guard let charger = devices.evChargers.first else {
            throw SystemError.chargersMissing
        }
        self.charger = charger
    }

    @Test("Setup-Device-Configuration")
    func setupDeviceConfiguration() async throws {
        try await self.charger.setupConfig()
    }

    @Test("Software-Lock-State")
    func softwareLockState() async throws {
        try await setLockState(to: .unlocked, expected: .unlocked)
        try await setLockState(to: .locked, expected: .locked)

        func setLockState(to value: LockState, expected: LockState) async throws {
            let newState = try await self.charger.setSoftwareLock(to: value)
            print("Actual charger software lock state: \(newState), Expected: \(expected) - Fullfilled: \(newState == expected ? "✔" : "✘")")
            #expect(newState == expected)
        }
    }

    @Test("Get-Hardware-Lock-State")
    func getHardwareLockState() async throws {
        let state = try await self.charger.getHardwareLockState()
        print("Actual charger hardware lock state: \(state)")
        #expect(state == .unlocked)
    }

    @Test("Get-Charging-State")
    func getChargingState() async throws {
        let state = try await self.charger.getChargerState()
        #expect(state != .unknown)
        print("Charger State: \(state)")
    }

    @Test("Get-EV-Plugged-State")
    func getEVPluggedState() async throws {
        let state = try await self.charger.getEVPluggedState()
        print("Charger EV Plugged State: \(state)")
        #expect(state != .unknown)
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
        let currLimits = try await self.charger.getFixedCurrentLimits()
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
            // Make sure to wait a bit after each call, especially when working with real devices. These devices most likely need some time to internally set the new setpoints and
            // bring the new values on the bus.
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        func setSetpoint(to value: Measurement<UnitElectricCurrent>, expected: Measurement<UnitElectricCurrent>) async throws {
            let currentSetpoint = try await self.charger.setCurrentLimit(to: value)
            print("Actual charger current limit setpoint: \(currentSetpoint), Expected: \(expected) - Fullfilled: \(currentSetpoint == expected ? "✔" : "✘")")
            #expect(currentSetpoint == expected)
        }
    }
}
