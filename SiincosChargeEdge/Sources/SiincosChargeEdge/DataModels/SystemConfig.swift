//
//  SystemConfig.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//

import Foundation
import Logging

/// Device Configutation
///
/// Device Configuration for ModbusRTU based EV chargers and power meters.
protocol DeviceConfig {
    var systemId: String { get }
    var chargerModel: SupportedCharger { get }
    var chargerBus: String { get }
    var meterModel: SupportedPowerMeter { get }
    var meterBus: String { get }
    var lineLength: UInt8 { get }
    var lineMaxCurrent: Measurement<UnitElectricCurrent> { get }
    var externalLoadLimiter: ExternalLoadLimiterType { get }
}

/// Cloud Configuration
///
/// Cloud configuration for MQTT client.
protocol CloudConfig {
    var cloudHost: String { get }
    var cloudPort: UInt16 { get }
    var cloudCACertPath: String { get }
    var cloudClientId: String { get }
    var cloudUsername: String { get }
    var cloudPassword: String { get }
}

/// System Configuration
///
/// System configuration for the Siincos Charge Edge system
struct SystemConfig: DeviceConfig, CloudConfig, Codable, CustomStringConvertible {
    let systemId: String
    let chargerModel: SupportedCharger
    let chargerBus: String
    let meterModel: SupportedPowerMeter
    let meterBus: String
    let lineLength: UInt8
    let lineMaxCurrent: Measurement<UnitElectricCurrent>
    let externalLoadLimiter: ExternalLoadLimiterType
    let cloudHost: String
    let cloudPort: UInt16
    let cloudCACertPath: String
    let cloudClientId: String
    let cloudUsername: String
    let cloudPassword: String

    let logger = ComponentSupplier.mainLogger

    enum CodingKeys: String, CodingKey {
        case systemId
        case chargerModel
        case chargerBus
        case meterModel
        case meterBus
        case lineLength
        case lineMaxCurrentA
        case externalLoadLimiter
        case cloudHost
        case cloudPort
        case cloudCACertPath
        case cloudClientId
        case cloudUsername
        case cloudPassword
    }

    /// Memberwise Initializer
    ///
    /// - Note: Memberwise initializer mainly used for running the tests
    init(systemId: String,
         chargerModel: SupportedCharger,
         chargerBus: String,
         meterModel: SupportedPowerMeter,
         meterBus: String,
         lineLength: UInt8,
         lineMaxCurrent: Measurement<UnitElectricCurrent>,
         externalLoadLimiter: ExternalLoadLimiterType,
         cloudHost: String,
         cloudPort: UInt16,
         cloudCACertPath: String,
         cloudClientId: String,
         cloudUsername: String,
         cloudPassword: String) throws {
        self.systemId = systemId
        self.chargerModel = chargerModel
        self.chargerBus = chargerBus
        self.meterModel = meterModel
        self.meterBus = meterBus
        self.lineLength = lineLength
        self.lineMaxCurrent = lineMaxCurrent
        self.externalLoadLimiter = externalLoadLimiter
        self.cloudHost = cloudHost
        self.cloudPort = cloudPort
        self.cloudCACertPath = cloudCACertPath
        self.cloudClientId = cloudClientId
        self.cloudUsername = cloudUsername
        self.cloudPassword = cloudPassword

        try self.validate()
    }

    /**
     Decodes a `SystemConfig` instance from the given decoder.
     This custom implementation decodes all properties directly, but expects the `lineMaxCurrent` value to be provided as a flat
     double under the key `lineMaxCurrentA` (amperes) in the JSON, and reconstructs it as a `Measurement<UnitElectricCurrent>`.
     - Parameter decoder: The decoder to read data from.
     - Throws: An error if reading from the decoder fails, or if the data is corrupted or otherwise invalid.
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.systemId = try container.decode(String.self, forKey: .systemId)
        self.chargerModel = try container.decode(SupportedCharger.self, forKey: .chargerModel)
        self.chargerBus = try container.decode(String.self, forKey: .chargerBus)
        self.meterModel = try container.decode(SupportedPowerMeter.self, forKey: .meterModel)
        self.meterBus = try container.decode(String.self, forKey: .meterBus)
        self.lineLength = try container.decode(UInt8.self, forKey: .lineLength)
        let lineMaxCurrentA = try container.decode(Double.self, forKey: .lineMaxCurrentA)
        self.lineMaxCurrent = Measurement(value: lineMaxCurrentA, unit: .amperes)
        self.externalLoadLimiter = try container.decode(ExternalLoadLimiterType.self, forKey: .externalLoadLimiter)
        self.cloudHost = try container.decode(String.self, forKey: .cloudHost)
        self.cloudPort = try container.decode(UInt16.self, forKey: .cloudPort)
        self.cloudCACertPath = try container.decode(String.self, forKey: .cloudCACertPath)
        self.cloudClientId = try container.decode(String.self, forKey: .cloudClientId)
        self.cloudUsername = try container.decode(String.self, forKey: .cloudUsername)
        self.cloudPassword = try container.decode(String.self, forKey: .cloudPassword)

        try self.validate()
    }

    /**
     Encodes this `SystemConfig` instance into the given encoder.
     This custom implementation encodes all properties directly, but flattens the `lineMaxCurrent` measurement to a plain double
     (amperes) under the key `lineMaxCurrentA` in the JSON for compatibility with external systems.
     - Parameter encoder: The encoder to write data to.
     - Throws: An error if any values are invalid for the encoder’s format.
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.systemId, forKey: .systemId)
        try container.encode(self.chargerModel, forKey: .chargerModel)
        try container.encode(self.chargerBus, forKey: .chargerBus)
        try container.encode(self.meterModel, forKey: .meterModel)
        try container.encode(self.meterBus, forKey: .meterBus)
        try container.encode(self.lineLength, forKey: .lineLength)
        try container.encode(self.lineMaxCurrent.converted(to: .amperes).value, forKey: .lineMaxCurrentA)
        try container.encode(self.externalLoadLimiter, forKey: .externalLoadLimiter)
        try container.encode(self.cloudHost, forKey: .cloudHost)
        try container.encode(self.cloudPort, forKey: .cloudPort)
        try container.encode(self.cloudCACertPath, forKey: .cloudCACertPath)
        try container.encode(self.cloudClientId, forKey: .cloudClientId)
        try container.encode(self.cloudUsername, forKey: .cloudUsername)
        try container.encode(self.cloudPassword, forKey: .cloudPassword)
    }

    /// Validate System Configuration
    ///
    /// Validate configuration to ensure compatibility between all settings parameters. Currently validating:
    /// - `lineLenght` is minimum 1 and does not exceed 10 devices
    /// -
    private func validate() throws {
        // Validate line length
        guard self.lineLength >= 1 && self.lineLength <= AppConstants.maxRS485BusDevices else {
            self.logger.critical("Provided line length has to be between 1 and \(AppConstants.maxRS485BusDevices), but was provided as \(self.lineLength)")
            throw SystemError.configurationIntegrityError
        }

        // Validate line max current
        let definedLineMaxCurrent = self.lineMaxCurrent.converted(to: .amperes).value
        let maximumAllowedLineMaxCurrent = Double(self.lineLength)*Double(AppConstants.maxChargerCurrentA)
        guard definedLineMaxCurrent <= maximumAllowedLineMaxCurrent else {
            self.logger.critical("Defined maximum system current (\(definedLineMaxCurrent)) exceeds the maximum allowed system current (\(maximumAllowedLineMaxCurrent)")
            throw SystemError.configurationIntegrityError
        }
    }

    var description: String {
        return """
            System ID: \(self.systemId),
            Charger Model: \(self.chargerModel),
            Charger Bus: \(self.chargerBus),
            Meter Model: \(self.meterModel),
            Meter Bus: \(self.meterBus),
            Line Length: \(self.lineLength),
            Line Max Current (A): \(self.lineMaxCurrent.value),
            External Load Limiter: \(self.externalLoadLimiter)
            Cloud: \(self.cloudHost):\(self.cloudPort)"
            """
    }
}

