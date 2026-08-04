//
//  SystemConfigTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 02.08.26.
//

import Testing
import Foundation
@testable import SiincosChargeEdge

@Suite("SystemConfigTests", .serialized)
class SystemConfigTests {

    /// Create a `SystemConfig` with valid defaults, allowing individual parameters to be overridden per test case
    private func makeSystemConfig(lineLength: UInt8 = 2,
                                  lineMaxCurrent: Measurement<UnitElectricCurrent> = Measurement(value: 32, unit: .amperes)) throws -> SystemConfig {
        return try SystemConfig(systemId: "test-system",
                                chargerModel: .mockCharger,
                                chargerBus: "/dev/ttyUSB0",
                                meterModel: .nope,
                                meterBus: "/dev/ttyUSB0",
                                lineLength: lineLength,
                                lineMaxCurrent: lineMaxCurrent,
                                cloudHost: "cloud.example.com",
                                cloudPort: 8883,
                                cloudCACertPath: "/opt/SiincosChargeEdge/Assets/ca.pem",
                                cloudClientId: "test-client",
                                cloudUsername: "test-user",
                                cloudPassword: "test-password")
    }

    // MARK: - Validate line length

    @Test("Line length within allowed bounds passes validation")
    func lineLengthValid() throws {
        let config = try self.makeSystemConfig(lineLength: AppConstants.maxRS485BusDevices)
        #expect(config.lineLength == AppConstants.maxRS485BusDevices)
    }

    @Test("Line length outside allowed bounds throws configurationIntegrityError")
    func lineLengthInvalid() {
        #expect(throws: SystemError.configurationIntegrityError) {
            try self.makeSystemConfig(lineLength: AppConstants.maxRS485BusDevices + 1)
        }
        #expect(throws: SystemError.configurationIntegrityError) {
            try self.makeSystemConfig(lineLength: 0)
        }
    }

    // MARK: - Validate line max current

    @Test("Line max current within allowed maximum passes validation")
    func lineMaxCurrentValid() throws {
        // For a line length of 2 the maximum allowed current is 2 * maxChargerCurrentA
        let allowedMaximum = Measurement<UnitElectricCurrent>(value: Double(2 * AppConstants.maxChargerCurrentA), unit: .amperes)
        let config = try self.makeSystemConfig(lineLength: 2, lineMaxCurrent: allowedMaximum)
        #expect(config.lineMaxCurrent == allowedMaximum)
    }

    @Test("Line max current exceeding allowed maximum throws configurationIntegrityError")
    func lineMaxCurrentInvalid() {
        let exceedingCurrent = Measurement<UnitElectricCurrent>(value: Double(2 * AppConstants.maxChargerCurrentA) + 1, unit: .amperes)
        #expect(throws: SystemError.configurationIntegrityError) {
            try self.makeSystemConfig(lineLength: 2, lineMaxCurrent: exceedingCurrent)
        }
    }
}
