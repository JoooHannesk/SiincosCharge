//
//  CompatibleDevices.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//

/// Compatible EV Charger
///
/// System compatible EV chargers are listed here
enum CompatibleCharger: String, Codable, CaseIterable {
    case senecWallboxProS11kW  = "SenecWallboxProS11kW"
}

/// Compatible Smart Meters
///
/// System compatible smart meters are listed here
enum CompatibleSmartMeter: String, Codable, CaseIterable {
    case nope = "Nope"
}
