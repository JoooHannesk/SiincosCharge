//
//  Helpers.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 07.07.26.
//


// This code is only used for the test cases - currently. Parts or implementations may be moved to the binary target sources in future.

import Foundation
@testable import SiincosChargeEdge

func unprefixTelemetry(_ flat: [String: Any], cpId: UInt8) -> [String: Any] {
    let prefix = "cp\(cpId)_"

    var result: [String: Any] = [
        "cpId": cpId
    ]

    for (key, value) in flat {
        guard key.hasPrefix(prefix) else { continue }

        let strippedKey = String(key.dropFirst(prefix.count))
        result[strippedKey] = value
    }

    return result
}

func deserializeChargingPoint(from str: String) throws -> ChargingPointStatus? {
    let data = Data(str.utf8)
        // make sure this JSON is in the format we expect
        if let flat = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            guard let firstKey = flat.keys.first,
                  let cpIdString = firstKey.split(separator: "_").first,
                  cpIdString.starts(with: "cp"),
                  let cpId = UInt8(cpIdString.dropFirst(2)) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid prefix"))
            }
            let normalized = unprefixTelemetry(flat, cpId: cpId)
            let data = try JSONSerialization.data(withJSONObject: normalized)
            return try JSONDecoder.customTelemetryCompatibleDecoder.decode(ChargingPointStatus.self, from: data)
    }
    return nil
}
