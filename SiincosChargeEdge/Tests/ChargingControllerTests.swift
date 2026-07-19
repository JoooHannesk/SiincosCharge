//
//  ChargingControllerTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 19.07.26.
//

import Foundation
import Testing
@testable import SiincosChargeEdge


@Suite("Charging-Controller-Tests", .serialized)
struct ChargingControllerTests {

    /// Static Device Config
    static var testSystemConfig: SystemConfig {
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
                                      cloudPassword: "")
            return config
        }
    }

    static var chargingController: ChargingController {
        get async throws {
            try await ChargingController(systemConfig: Self.testSystemConfig)
        }
    }

    func getPluggedInChargingPointId() async throws -> UInt8 {
        
    }

//    func getTestChargingSession() async throws -> ChargingSession {
//        
//    }

    @Test("Test-Request-Charging-Session")
    func testRequestChargingSession() async throws {

    }

}
