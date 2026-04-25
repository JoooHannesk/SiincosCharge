//
//  ChargingSystemTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 21.04.26.
//


import Testing
import Foundation
@testable import SiincosChargeEdge


class ChargingPointTests {

    var chargingPoints: [ChargingPoint] = []

    init() async throws {
        let systemConfig = try ComponentSupplier.getSystemConfig()
        let devices = try ComponentSupplier.getDevices(for: systemConfig)
        for (evCharger, powerMeter) in zip(devices.0, devices.1) {
            self.chargingPoints.append(try await ChargingPoint(evCharger: evCharger, powerMeter: powerMeter))
        }
    }

    @Test("Charging-System-Consistency-Check")
    func chargingSystemConsistencyCheck() async throws {
        let mockCharger = MockCharger(unitId: 2, modelName: .mockCharger)
        let mockChargerPowerMeter = MockChargerPowerMeter(unitId: 1, modelName: .nope)
        let error = await #expect(throws: SystemError.unitIdMissmatch) {
            let _ = try await ChargingPoint(evCharger: mockCharger, powerMeter: mockChargerPowerMeter)
        }
        #expect(error == .unitIdMissmatch)
    }

    @Test("Test-Charging-System-Properties")
    func chargingSystemProperties() async throws {
        for chargingPoint in chargingPoints {
            let chargingState = try await chargingPoint.chargingState
            #expect(chargingState != .unknown)
            let pluggedState = try await chargingPoint.evState
            #expect(pluggedState != .unknown)
            #expect(await chargingPoint.chargingPermission == .disabled)

            let chargingCurrent = try await chargingPoint.chargingCurrent
            #expect(chargingCurrent.currentL1!.value >= 0.0 && chargingCurrent.currentL2!.value >= 0.0 && chargingCurrent.currentL3!.value >= 0.0 && chargingCurrent.currentAverage.value >= 0.0)

            let chargingPower = try await chargingPoint.chargingPower
            #expect(chargingPower.powerL1!.value >= 0.0 && chargingPower.powerL2!.value >= 0.0 && chargingPower.powerL3!.value >= 0.0 && chargingPower.powerTotal.value >= 0.0)

            let gridVoltage = try await chargingPoint.gridVoltage
            #expect(gridVoltage.voltageL1!.value > 200 && gridVoltage.voltageL2!.value > 200 && gridVoltage.voltageL3!.value > 200)

            let meterReading = try await chargingPoint.meterReading
            #expect(meterReading.value >= 0.0)
        }
    }

    @Test("Charging-System-Initializer")
    func chargingSystemInit() throws {
        #expect(self.chargingPoints.count > 0)
    }

    @Test("Enable-Charging")
    func enableCharging() async throws {
        for chargingPoint in self.chargingPoints {
            let charging = try await chargingPoint.enableCharging()
            #expect(charging == .enabled)
            #expect(await chargingPoint.chargingPermission == .enabled)
        }
    }

    @Test("Disable-Charging")
    func disableCharging() async throws {
        for chargingPoint in self.chargingPoints {
            let charging = try await chargingPoint.disableCharging()
            #expect(charging == .disabled)
            #expect(await chargingPoint.chargingPermission == .disabled)
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
        for chargingPoint in self.chargingPoints {
            for testValue in testValuesFrame {
                let chargerAckCurrent = try await chargingPoint.setChargingCurrent(to: Measurement(value: testValue.0, unit: .amperes))
                #expect(testValue.1 == chargerAckCurrent.value)
            }
        }
    }
}
