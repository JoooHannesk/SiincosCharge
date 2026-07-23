//
//  Helpers.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 19.07.26.
//

import Foundation


extension JSONEncoder {

    /// Encoder configured for the project-wide JSON conventions
    ///
    /// Dates are encoded as whole (integer) milliseconds since 1970, matching the format
    /// expected by third-party systems, e.g. cloud backends. Sub-millisecond precision is
    /// rounded away so values round-trip deterministically with
    /// ``JSONDecoder/customTelemetryCompatibleDecoder``.
    /// - Note: Use this instead of `JSONEncoder()` whenever encoding data models.
    static var customTelemetryCompatibleEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64((date.timeIntervalSince1970 * 1000).rounded()))
        }
        return encoder
    }
}

extension JSONDecoder {

    /// Decoder configured for the project-wide JSON conventions
    ///
    /// Dates are decoded from whole (integer) milliseconds since 1970, the counterpart to
    /// ``JSONEncoder/customTelemetryCompatibleEncoder``.
    /// - Note: Use this instead of `JSONDecoder()` whenever decoding data models.
    static var customTelemetryCompatibleDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let milliseconds = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
        }
        return decoder
    }
}

enum DataModelsHelpers {

    /// Get DateTime string
    ///
    /// Get a datetime string from a provided date with format `yyyy-MM-dd-HH-mm-ss` for local timezone
    /// - Parameters date: date to get a datetime string from
    /// - Returns: the datetime string
    static func getDateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: date)
    }
}
