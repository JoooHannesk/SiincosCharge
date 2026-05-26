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


    // MARK: - Chargers with integrated Power Meters

    /// Senec Wallbox Pro S
    ///
    /// Charger with ModbusRTU connectivity and integrated power meter.
    /// Modbus start address = 1; The first device on the bus **must have** unit id 1, incrementing
    /// the unit id by 1 for every additional device.
    /// Bus device lenght (line lenght) must not exceed 16 devices!
    case senecWallboxProS11kW  = "SenecWallboxProS11kW"

    /// Mock Charger
    ///
    /// A simple mock charger for testing and try runs without a physical
    /// EV charger.
    case mockCharger = "MockCharger"

    // MARK: - Chargers without integrated Power Meters

    // MARK: - Unsupported charger defined in configuration
    
    /// Unknown Charger
    ///
    /// In case an unsupported charger is defined, it will be referenced as `.unknown`. This
    /// leads to overall system instability and limited reliability.
    case unknown = "Unknown"
}

/// Supported and compatible Power Meters
///
/// System compatible power meters are listed here.
/// This list refers to the external power meters onyl.
enum SupportedPowerMeter: String, Codable, CaseIterable {

    /// Janitza Smart Meter B23 312-10J
    ///
    /// Dedicated Modbus RTU power meter
    case janitzaSmartMeterB2331210J = "JanitzaSmartMeterB2331210J"

    /// No Power Meter
    ///
    /// No dedicated power meter is installed.
    /// This working mode is possible, but indicates that no MID compatible power
    /// meter is present.
    case nope = "Nope"

    // MARK: - Unsupported Power Meter defined in configuration

    /// Unknown Power Meter
    ///
    /// In case an unsupported power meter is defined, it will be referenced as `.unknown`. This
    /// leads to overall system instability and limited reliability.
    case unknown = "Unknown"
}
