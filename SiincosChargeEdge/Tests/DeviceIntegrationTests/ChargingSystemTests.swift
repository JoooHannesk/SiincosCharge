//
//  ChargingSystemTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 27.05.26.
//


import Testing
import Foundation
@testable import SiincosChargeEdge

@Suite("ChargingSystemTests")
class ChargingSystemTests {

    let systemConfig: DeviceConfig
    let chargingSystem: ChargingSystem

    init() async throws {
        systemConfig = try ComponentSupplier.getSystemConfig()
        chargingSystem = try await ChargingSystem(config: systemConfig)
    }

    @Test("Test-Charging-System-Creation")
    func testChargingSystemCreation() async throws {
        #expect(self.chargingSystem.chargingPointContainer.count == systemConfig.lineLength)

    }

}
