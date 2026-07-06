//
//  TBMQTTBackendDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 06.07.26.
//

import Foundation

protocol JsonStringConvertible: Codable {
    var asJson: String? { get }
}

extension JsonStringConvertible {

    /// Return object as JSON
    ///
    /// Convert object to JSON and return as string. This functionality is required
    /// when passing data to third-party systems, e.g. cloud backends.
    /// - Note: If conversion fails, `nil` is returned.
    var asJson: String? {
        var asJson: String? = nil
        let encoder = JSONEncoder()
        //encoder.outputFormatting = .prettyPrinted
        let data = try? encoder.encode(self)
        if let data {
            asJson = String(data: data, encoding: .utf8)
        }
        return asJson
    }
}

extension ChargingSystemInformation: JsonStringConvertible {

    enum CodingKeys: String, CodingKey {
        case appVersion, chargerModel, meterModel, chargingPoints, lineMaxCurrentA
    }

    /// Encodes ChargingSystemInformation to a flat JSON structure.
    ///
    /// - Note: The `lineMaxCurrent` property is encoded as a single numeric value using the key `lineMaxCurrentA` (amperes only), for interoperability with flat-data systems like MQTT/ThingsBoard.
    /// - Throws: An error if any value fails to encode.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(chargerModel, forKey: .chargerModel)
        try container.encode(meterModel, forKey: .meterModel)
        try container.encode(chargingPoints, forKey: .chargingPoints)
        try container.encode(lineMaxCurrent.value, forKey: .lineMaxCurrentA)
    }

    /// Decodes ChargingSystemInformation from a flat JSON structure.
    ///
    /// - Note: The `lineMaxCurrentA` key is decoded as a numeric value in amperes and reconstructed as a Measurement<UnitElectricCurrent>.
    /// - Throws: An error if any value fails to decode or is missing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.chargerModel = try container.decode(SupportedCharger.self, forKey: .chargerModel)
        self.meterModel = try container.decode(SupportedPowerMeter.self, forKey: .meterModel)
        self.chargingPoints = try container.decode(UInt8.self, forKey: .chargingPoints)
        let value = try container.decode(Double.self, forKey: .lineMaxCurrentA)
        self.lineMaxCurrent = Measurement(value: value, unit: UnitElectricCurrent.amperes)
    }
}

extension ChargingSystemStatus: JsonStringConvertible {
    
}
