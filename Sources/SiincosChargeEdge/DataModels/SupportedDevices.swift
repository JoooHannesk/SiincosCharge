//
//  SupportedDevices.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//

/// Supported and compatible EV Charger
///
/// System compatible EV chargers are listed here
enum SupportedCharger: String, Codable, CaseIterable {
    case mockCharger = "MockCharger"
    case senecWallboxProS11kW  = "SenecWallboxProS11kW"
}

/// Supported and compatible Power Meters
///
/// System compatible smart power meters are listed here. This list
/// refers to the external power meters onyl.
enum SupportedPowerMeter: String, Codable, CaseIterable {
    case nope = "Nope"
}
