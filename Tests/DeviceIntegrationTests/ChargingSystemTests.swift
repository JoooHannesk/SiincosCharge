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

    init() async throws {
        let systemConfig = try ComponentSupplier.getSystemConfig()
        let devices = try ComponentSupplier.getDevices(for: systemConfig)

        for (evCharger, powerMeter) in zip(devices.0, devices.1) {
            self.chargingSystems.append(try await ChargingSystem(evCharger: evCharger, powerMeter: powerMeter))
        }
    }

    @Test("Charging-System-Consistency-Check")
    func chargingSystemConsistencyCheck() async throws {
        let mockCharger = MockCharger(unitId: 2, modelName: .mockCharger)
        let mockChargerPowerMeter = MockChargerPowerMeter(unitId: 1, modelName: .nope)
        let error = await #expect(throws: SystemError.unitIdMissmatch) {
            let _ = try await ChargingSystem(evCharger: mockCharger, powerMeter: mockChargerPowerMeter)
        }
        #expect(error == .unitIdMissmatch)
    }

    @Test("Test-Charging-System-Properties")
    func chargingSystemProperties() async throws {
        for chargingSystem in chargingSystems {
            let chargingState = try await chargingSystem.chargingState
            #expect(chargingState != .unknown)
            let pluggedState = try await chargingSystem.evState
            #expect(pluggedState != .unknown)
            #expect(await chargingSystem.chargingPermission == .disabled)
        }
    }

    @Test("Charging-System-Initializer")
    func chargingSystemInit() throws {
        #expect(self.chargingSystems.count > 0)
    }

    @Test("Enable-Charging")
    func enableCharging() async throws {
        for chargingSystem in self.chargingSystems {
            let charging = try await chargingSystem.enableCharging()
            #expect(charging == .enabled)
        }
    }

    @Test("Disable-Charging")
    func disableCharging() async throws {
        for chargingSystem in self.chargingSystems {
            let charging = try await chargingSystem.disableCharging()
            #expect(charging == .disabled)
        }
    }

    @Test("Set-Charging-Current-Limit")
    func setChargingCurrentLimit() async throws {
        let testValuesFrame = [
            // (setpoint, expected)
            (4.0, 6.0),
            (6.0, 6.0),
            (8.5, 8.0),
            (10.0, 10.0),
            (16.0, 16.0),
            (18.0, 16.0),
        ]
        for chargingSystem in self.chargingSystems {
            for testValue in testValuesFrame {
                let chargerAckCurrent = try await chargingSystem.setChargingCurrent(to: testValue.0)
                #expect(testValue.1 == chargerAckCurrent)
            }
        }
    }
}
