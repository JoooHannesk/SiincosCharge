//
//  Helpers.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 19.07.26.
//

import Foundation


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
