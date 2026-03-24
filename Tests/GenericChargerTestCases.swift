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
    let charger: CarCharger

    init(charger: CarCharger) {
        self.charger = charger
    }

    /// Run all tests
    func runAllTests() async throws {
        try await self.getChargingState()
        try await self.getInternalTemperature()
        try await self.getHardwareCurrentLimits()
    }

    // MARK: Private Test Cases

    private func getChargingState() async throws {
        let state = try await self.charger.getChargingState()
        #expect(state != .unknown)
        print("Charger State: \(state)")
    }

    private func getInternalTemperature() async throws {
        let temperature = try await self.charger.getInternalTemperature()
        let tempLow = Measurement(value: -25.0, unit: UnitTemperature.celsius)
        let tempHigh = Measurement(value: 40.0, unit: UnitTemperature.celsius)
        print("Charger internal temperature: \(temperature)")
        #expect(temperature > tempLow && temperature < tempHigh)
    }

    private func getHardwareCurrentLimits() async throws {
        let currLimits = try await self.charger.getHardwareCurrentLimits()
        let currLow = Measurement(value: 6.0, unit: UnitElectricCurrent.amperes)
        let currHigh = Measurement(value: 16.0, unit: UnitElectricCurrent.amperes)
        print("Charger hardware current limits: \(currLimits)")
        #expect(currLow == currLimits.minimal && currHigh == currLimits.maximal)
    }
}
