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

    let chargingController: ChargingController

    init() async throws {
        self.chargingController = try await ChargingController(systemConfig: Self.testSystemConfig)
    }

    /// Get charging points sorted by ``EVState``
    ///
    /// Collects all charging point ids grouped by their ``EVState``:
    /// one array for `.pluggedIn` and one array for `.unplugged`.
    ///
    /// - Returns: Charging point id of the first charging point whose EV state is `.pluggedIn`
    func getChargingPointIdsByPluggedState() async throws -> (pluggedIn: [UInt8], unplugged: [UInt8]) {
        let chargingController = self.chargingController
        let chargingPoints = await chargingController.chargingSystem?.chargingPointContainer.chargingPoints ?? [:]

        var pluggedInChargingPointIds: [UInt8] = []
        var unpluggedChargingPointIds: [UInt8] = []

        for (cpId, chargingPoint) in chargingPoints.sorted(by: { $0.key < $1.key }) {
            switch try await chargingPoint.evState {
            case .pluggedIn:
                pluggedInChargingPointIds.append(cpId)
            case .unplugged:
                unpluggedChargingPointIds.append(cpId)
            default:
                break
            }
        }
        return (pluggedIn: pluggedInChargingPointIds,
                unplugged: unpluggedChargingPointIds)
    }

    /// Create a new charging session
    ///
    /// - Parameter cpId: Charging point id
    /// - Returns: Simple chargin session with status `.running`
    func getChargingSession(cpId: UInt8) async throws -> ChargingSession {
        return ChargingSession(cpId: cpId,
                               userName: "mockUser@mockserver.com",
                               chargingSessionStatus: .running,
                               chargingCurrentSetpoint: Measurement(value: 10.0, unit: .amperes))
    }

    @Test("Test-Request-Charging-Session")
    func testRequestChargingSession() async throws {
        let chargingPointId = try await self.getChargingPointIdsByPluggedState().pluggedIn.first
        try #require(chargingPointId != nil)
        let chargingSession = try await self.getChargingSession(cpId: chargingPointId!)
        await self.chargingController.requestChargingSession(chargingSession)
        print(chargingSession)
        let startedChargingSession = await self.chargingController.chargingSystem?.chargingPointContainer.getChargingTask(by: chargingSession.cpId)
        try #require(startedChargingSession != nil)
        #expect(chargingSession.cpId == startedChargingSession?.cpId); #expect(chargingSession.userName == startedChargingSession?.userName)
        try #require(startedChargingSession!.startTime != nil); #expect(startedChargingSession!.startTime! < Date())
        try #require(startedChargingSession!.meterReadingStart != nil)
    }

}
