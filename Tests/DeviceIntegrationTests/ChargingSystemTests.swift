//
//  ChargingSystemTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 21.04.26.
//


import Testing
import Foundation
@testable import SiincosChargeEdge


class ChargingSystemTests {

    var chargingSystems: [ChargingSystem] = []

    init() throws {
        let systemConfig = try ComponentSupplier.getSystemConfig()
        let devices = try ComponentSupplier.getDevices(for: systemConfig)

        for (evCharger, powerMeter) in zip(devices.0, devices.1) {
            self.chargingSystems.append(ChargingSystem(evCharger: evCharger, powerMeter: powerMeter))
        }
    }

    @Test("Charging-System-Initializer")
    func chargingSystemInit() throws {
        #expect(self.chargingSystems.count > 0)
    }
}
