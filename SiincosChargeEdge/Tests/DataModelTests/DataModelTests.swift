//
//  DataModelTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 03.07.26.
//

import Testing
import Foundation
@testable import SiincosChargeEdge


/// Data Model Tests
///
/// Test data model related functionality, e.g. conversion and encoding
@Suite("Data-Model-Tests", .serialized)
struct DataModelTests {

    @Test("Test-JSON-Encoding-For-ChargingSystemInformation-Data-Model")
    func averageCurrent() throws {
        let csysInfo = ChargingSystemInformation(appVersion: "0.0.4",
                                                 chargerModel: .senecWallboxProS11kW,
                                                 meterModel: .janitzaSmartMeterB2331210J,
                                                 chargingPoints: 3,
                                                 lineMaxCurrentA: 16)
        try #require(csysInfo.asJson != nil)
        if let jsonString = csysInfo.asJson {
            let jsonData = jsonString.data(using: .utf8)!
            let csysInfo2 = try JSONDecoder().decode(ChargingSystemInformation.self, from: jsonData)
            #expect(csysInfo == csysInfo2)
        }
    }
}
