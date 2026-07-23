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

    /// Create a new mock charging session
    ///
    /// Create a new mock charging session based on a mock charger which is ready to accept a charging request (ev status: pluggedIn)
    ///
    /// - Returns: Simple chargin session with status `.running`
    func getChargingSession(cpId: UInt8? = nil, userName: String = "mockUser@mockserver.com", status: ChargingSessionStatus = .running) async throws -> ChargingSession {
        let chargingPointId = try await self.getChargingPointIdsByPluggedState().pluggedIn.first
        try #require(chargingPointId != nil)
        return ChargingSession(cpId: cpId ?? chargingPointId!,
                               userName: userName,
                               chargingSessionStatus: status,
                               chargingCurrentSetpoint: Measurement(value: 10.0, unit: .amperes))
    }

    @Test("Test-Request-New-Charging-Session")
    func testRequestNewChargingSession() async throws {
        let chargingSession = try await self.getChargingSession()
        await self.chargingController.requestChargingSession(chargingSession)
        let startedChargingSession = await self.chargingController.chargingSystem?.chargingPointContainer.getChargingTask(by: chargingSession.cpId)
        try #require(startedChargingSession != nil)
        #expect(chargingSession.cpId == startedChargingSession?.cpId); #expect(chargingSession.userName == startedChargingSession?.userName)
        try #require(startedChargingSession!.startTime != nil); #expect(startedChargingSession!.startTime! < Date())
        try #require(startedChargingSession!.meterReadingStart != nil)
    }

    @Test("Test-Request-Pause-Resume-Charging-Session")
    func testRequestPauseAndResumeExistingChargingSession() async throws {
        let chargingSession = try await self.getChargingSession()
        var newSession = await self.chargingController.requestChargingSession(chargingSession)
        try #require(newSession != nil)
        try #require(newSession?.status == .running)
        newSession?.status = .paused
        let pausedChargingSession = await self.chargingController.requestChargingSession(newSession!)
        #expect(pausedChargingSession?.status == .paused)
        newSession?.status = .running
        let resumedChargingSession = await self.chargingController.requestChargingSession(newSession!)
        #expect(resumedChargingSession?.status == .running)
    }

    @Test("Test-Request-Pause-Charging-Session-Different-User")
    func testRequestPauseExistingChargingSessionFromDifferentUser() async throws {
        let chargingSessionOwner = try await self.getChargingSession()
        let chargingSessionDifferentOwner = try await self.getChargingSession(cpId: chargingSessionOwner.cpId, userName: "differentUser@mockserver.com", status: .paused)
        let thisSession = await self.chargingController.requestChargingSession(chargingSessionOwner)
        try #require(thisSession != nil)
        try #require(thisSession?.status == .running)
        let changedSession = await self.chargingController.requestChargingSession(chargingSessionDifferentOwner)
        #expect(changedSession == nil)
    }

    @Test("Test-Request-Resume-Charging-Session-Different-User")
    func testRequestResumeExistingChargingSessionFromDifferentUser() async throws {
        var chargingSessionOwner = try await self.getChargingSession()
        let chargingSessionDifferentOwner = try await self.getChargingSession(cpId: chargingSessionOwner.cpId, userName: "differentUser@mockserver.com")
        var thisSession = await self.chargingController.requestChargingSession(chargingSessionOwner)
        try #require(thisSession != nil)
        try #require(thisSession?.status == .running)
        chargingSessionOwner.status = .paused
        thisSession = await self.chargingController.requestChargingSession(chargingSessionOwner)
        try #require(thisSession != nil)
        try #require(thisSession?.status == .paused)
        let changedSession = await self.chargingController.requestChargingSession(chargingSessionDifferentOwner)
        #expect(changedSession == nil)
        let chargingSession = await self.chargingController.chargingSystem!.chargingPointContainer.getChargingTask(by: chargingSessionOwner.cpId)
        #expect(chargingSession! == thisSession!)
    }

    @Test("Test-Request-Finish-Charging-Session")
    func testRequestFinishExistingChargingSession() async throws {
        let chargingSession = try await self.getChargingSession()
        var newSession = await self.chargingController.requestChargingSession(chargingSession)
        try #require(newSession != nil)
        newSession!.status = .finished
        let finishedChargingSession = await self.chargingController.requestChargingSession(newSession!)
        try #require(finishedChargingSession != nil)
        #expect(finishedChargingSession!.status == .finished)
        #expect(finishedChargingSession!.meterReadingEnd!.value > finishedChargingSession!.meterReadingStart!.value)
        #expect(finishedChargingSession!.totalEnergyConsumed!.value > 0)
        let noSession = await self.chargingController.chargingSystem!.chargingPointContainer.getChargingTask(by: chargingSession.cpId)
        #expect(noSession == nil)
    }

    @Test("Test-Finish-Existing-Charging-Session-Different-User")
    func testRequestFinishExistingChargingSessionFromDifferentOwner() async throws {
        let chargingSessionOwner = try await self.getChargingSession()
        let chargingSessionDifferentOwner = try await self.getChargingSession(cpId: chargingSessionOwner.cpId, userName: "differentUser@mockserver.com", status: .finished)
        let thisSession = await self.chargingController.requestChargingSession(chargingSessionOwner)
        try #require(thisSession != nil)
        try #require(thisSession?.status == .running)
        let changedSession = await self.chargingController.requestChargingSession(chargingSessionDifferentOwner)
        #expect(changedSession == nil)
    }

    @Test("Test-Schedule-Charging-Session")
    func testScheduleChargingSession() async throws {
        var scheduledSession = try await self.getChargingSession(status: .scheduled)
        var thisSession = await self.chargingController.requestChargingSession(scheduledSession)
        #expect(thisSession == nil)
        scheduledSession.startTime = Date().addingTimeInterval(3600)
        scheduledSession.endTime = Date().addingTimeInterval(7200)
        thisSession = await self.chargingController.requestChargingSession(scheduledSession)
        #expect(thisSession?.status == .scheduled)
    }

}
