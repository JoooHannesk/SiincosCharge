//
//  DeviceIntegrationTestsGenericCharger.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 24.03.26.
//

import Testing
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

    func getChargingState() async throws {
        let state = try await self.charger.getChargingState()
        #expect(state != .unknown)
        print(state)
    }
}
