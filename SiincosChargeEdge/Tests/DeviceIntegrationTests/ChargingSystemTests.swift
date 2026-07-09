//
//  ChargingSystemTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 27.05.26.
//


import Testing
import Foundation
@testable import SiincosChargeEdge

@Suite("ChargingSystemTests", .serialized)
class ChargingSystemTests {

    static var deviceConfig: DeviceConfig {
        get async throws {
            try ComponentSupplier.getSystemConfig()
        }
    }
    let chargingSystem: ChargingSystem
    let startingCpId: UInt8 = 1
    let allChargingPointIds: ClosedRange<UInt8>

    init() async throws {
        chargingSystem = try await ChargingSystem(config: Self.deviceConfig)
        allChargingPointIds = try await startingCpId...Self.deviceConfig.lineLength
    }

    @Test("Test-Charging-System-Creation")
    func testChargingSystemCreation() async throws {
        #expect(try await self.chargingSystem.chargingPointContainer.count == Self.deviceConfig.lineLength)
    }

    @Test("Get-EV-Plugged-State")
    func testGetEVPluggedState() async throws {
        for cpId in allChargingPointIds {
            print(cpId)
            let result = try await self.chargingSystem.getEvState(chargingPointId: cpId)
            #expect(result != .unknown)
        }
    }

    @Test("Get-EV-Charging-State")
    func testGetEVChargingState() async throws {
        for cpId in allChargingPointIds {
            let result = try await self.chargingSystem.getChargingState(chargingPointId: cpId)
            #expect(result != .unknown)
        }
    }

    @Test("Get-Charging-Permission")
    func testGetChargingPermission() async throws {
        for cpId in allChargingPointIds {
            let result = await self.chargingSystem.getChargingPermission(chargingPointId: cpId)
            #expect(result != .unknown)
        }
    }

    @Test("Set-Charging-Permission")
    func testSetChargingPermission() async throws {
        for cpId in allChargingPointIds {
            var result = try await self.chargingSystem.setChargingPermission(to: .enabled, for: cpId)
            #expect(result == .enabled)
            result = try await self.chargingSystem.setChargingPermission(to: .disabled, for: cpId)
            #expect(result == .disabled)
        }
    }

    @Test("Charging-Current-Setpoint")
    func testChargingCurrentSetpoint() async throws {
        let testValuesFrame = [
            // (setpoint, expected)
            (4.0, 6.0),
            (6.0, 6.0),
            (8.5, 8.0),
            (10.0, 10.0),
            (16.0, 16.0),
            (18.0, 16.0),
        ]

        for cpId in allChargingPointIds {
            for setExpected in testValuesFrame {
                var result = try await self.chargingSystem.setChargingCurrentSetpoint(to: Measurement(value: setExpected.0, unit: UnitElectricCurrent.amperes), for: cpId)
                #expect(result == Measurement(value: setExpected.1, unit: UnitElectricCurrent.amperes))
                result = try await self.chargingSystem.getChargingCurrenSetpoint(chargingPointId: cpId)
                #expect(result == Measurement(value: setExpected.1, unit: UnitElectricCurrent.amperes))
            }
        }
    }

    @Test("Actual-Charging-Current")
    func testActualChargingCurrent() async throws {
        for cpId in allChargingPointIds {
            let result = try await self.chargingSystem.getChargingCurrent(chargingPointId: cpId)
            #expect(result.currentL1 != nil)
        }
    }

    @Test("Get-Meter-Reading")
    func testGetMeterReading() async throws {
        for cpId in allChargingPointIds {
            let result = try await self.chargingSystem.getMeterReading(chargingPointId: cpId)
            #expect(result.value > 0.0)
        }
    }

    @Test("Get-Charging-Power")
    func testGetChargingPower() async throws {
        for cpId in allChargingPointIds {
            let result = try await self.chargingSystem.getChargingPower(chargingPointId: cpId)
            #expect(result.powerL1 != nil)
        }
    }

    @Test("Get-Grid-Voltage")
    func testGetGridVoltage() async throws {
        for cpId in allChargingPointIds {
            let result = try await self.chargingSystem.getGridVoltage(chargingPointId: cpId)
            #expect(result.voltageL1 != nil && result.voltageL2 != nil && result.voltageL3 != nil)
        }
    }
}

@Suite("ChargingSystemLoadBalancerTests", .serialized)
class ChargingSystemLoadBalancerTests {

    /// Static Device Config
    static var deviceConfig: DeviceConfig {
        get async throws {
            let config = SystemConfig(systemId: "TestcaseConfig",
                                      chargerModel: .mockCharger,
                                      chargerBus: "",
                                      meterModel: .nope,
                                      meterBus: "",
                                      lineLength: 6,
                                      lineMaxCurrent: Measurement(value: 32.0, unit: .amperes),
                                      cloudHost: "",
                                      cloudPort: 0,
                                      cloudCACertPath: "",
                                      cloudClientId: "",
                                      cloudUsername: "",
                                      cloudPassword: "") as DeviceConfig
            return config
        }
    }

    /// Charging System (SUT)
    let chargingSystem: ChargingSystem

    init() async throws {
        chargingSystem = try await ChargingSystem(config: Self.deviceConfig)
    }

    @Test("Force-Setpoint-is-below-system-max-current")
    func testForceSetpointIsBelowSystemMaxCurrent() async throws {
        let currentSetpointChargingPoint = try await self.chargingSystem.updateLoadBalancedCurrent(forceSetpoint: Measurement(value: 64.0, unit: .amperes))
        #expect(currentSetpointChargingPoint.value <= 32.0)
    }

    @Test("Test-Load-Balancer")
    func testLoadBalancerIsLimitting() async throws {
        let currentLimitedBalancer = try await self.chargingSystem.updateLoadBalancedCurrent()
        let chargingPointsCharging = try await self.chargingSystem.chargingPointsCharging == 0 ? 1 : try await self.chargingSystem.chargingPointsCharging
        let chargingCurrentLimitExpectation = try await Self.deviceConfig.lineMaxCurrent.value / Double(chargingPointsCharging)
        #expect(currentLimitedBalancer.value == chargingCurrentLimitExpectation)
    }

}
