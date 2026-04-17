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
    case mockCharger = "MockCharger"
    case senecWallboxProS11kW  = "SenecWallboxProS11kW"
}

/// Compatible Power Meters
///
/// System compatible smart power meters are listed here. This list
/// refers to the external power meters onyl.
enum CompatiblePowerMeter: String, Codable, CaseIterable {
    case nope = "Nope"
}
