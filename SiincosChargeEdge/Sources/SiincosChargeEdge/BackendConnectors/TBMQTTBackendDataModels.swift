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
