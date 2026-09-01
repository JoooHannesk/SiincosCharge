//
//  TBMQTTBackendDataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 06.07.26.
//

import Foundation
import SiincosChargeDataModels

protocol JsonStringConvertible: Codable {
    var asJson: String? { get }
}

/// Easily export the object as JSON String
///
extension JsonStringConvertible {

    /// Return object as JSON
    ///
    /// Convert object to JSON and return as string. This functionality is required
    /// when passing data to third-party systems, e.g. cloud backends.
    /// - Returns: Object as JSON String
    /// - Note: If conversion fails, `nil` is returned.
    var asJson: String? {
        var asJson: String? = nil
        let encoder = JSONEncoder.customTelemetryCompatibleEncoder
        //encoder.outputFormatting = .prettyPrinted
        let data = try? encoder.encode(self)
        if let data {
            asJson = String(data: data, encoding: .utf8)
        }
        return asJson
    }
}

protocol SerializedJsonStringConvertible: JsonStringConvertible {
    var cpId: UInt8 { get }

}

/// Easily export the object as serialized JSON String
///
/// Serialize to a flattend JSON string, tagging the properties with their corresponding `cpId`.
/// - Note: When pushing to IoT platforms, e.g. ThingsBoard, it is recommended to flatten the
/// data structure when intensive use of dashboarding is considered.
extension SerializedJsonStringConvertible {

    /// Easily export the object as serialized JSON String
    ///
    /// Serialize to a flattend JSON string, tagging the properties with their corresponding `cpId`.
    /// - Returns: Object as serialized JSON String
    /// - Note: When pushing to IoT platforms, e.g. ThingsBoard, it is recommended to flatten the
    /// data structure when intensive use of dashboarding is considered.
    var asSerializedJson: String? {
        var asDict: [String: Any]? = nil
        if let data = try? JSONEncoder.customTelemetryCompatibleEncoder.encode(self) {
            asDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }

        let prefix = "cp\(cpId)_"

        if let asDict {
            let serializedDict: [String: Any] = Dictionary(uniqueKeysWithValues: asDict.compactMap { key, value in
                guard key != "cpId" else { return nil }
                return ("\(prefix)\(key)", value)
            })
            if let data = try? JSONSerialization.data(withJSONObject: serializedDict, options: []),
               let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        }
        return nil
    }
}
