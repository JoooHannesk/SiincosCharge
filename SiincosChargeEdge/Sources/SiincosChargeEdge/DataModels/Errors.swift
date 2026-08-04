//
//  Errors.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 03.04.26.
//

import Foundation
import ModbusSerial

/// System Errors
///
enum SystemError: String, RawRepresentable, Codable, Error {
    case configFileNotFound
    case configurationIntegrityError
    case boundaryViolation
    case dataMissing
    case chargersMissing
    case powerMetersMissing
    case deviceConfigurationError
    case unitIdMismatch
    case unsupportedDevice
    case mqttCommunicationError
    case mqttConnectError
    case modbusRTUCommunicationError
    case unknownError
}


extension SystemError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configFileNotFound:
            return "Configuration file not found or not readable!"
        case .configurationIntegrityError:
            return "Configuration file contains invalid configurations! Aborting!"
        case .boundaryViolation:
            return "Upper and lower bounds do not match!"
        case .dataMissing:
            return "Device did not return data!"
        case .chargersMissing:
            return "Charger(s) not found! Config invalid?"
        case .powerMetersMissing:
            return "No power meters found! Config invalid?"
        case .deviceConfigurationError:
            return "Device did not acknowledge desired configuration! Aborting!"
        case .unitIdMismatch:
            return "Charger and power meter unit ID missmatch! Aborting!"
        case .unsupportedDevice:
            return "Provided device not supported! Aborting!"
        case .mqttCommunicationError:
            return "Error communicating with the MQTT broker!. Aborting!"
        case .mqttConnectError:
            return "Error connecting to the MQTT Server! Aborting!"
        case .modbusRTUCommunicationError:
            return "Error communicating with a device via Modbus RTU!"
        case .unknownError:
            return "An unknown error occurred!"
        }
    }
}


extension SystemError {
    /// Converts errors thrown by underlying libraries to a matching ``SystemError`` case.
    ///
    /// Extend the `switch` with an additional pattern when integrating a new library
    /// whose errors should map to a dedicated ``SystemError`` case.
    init(mapping error: Error) {
        switch error {
        case let systemError as SystemError:
            self = systemError
        case is RTUClientError:
            self = .modbusRTUCommunicationError
        default:
            self = .unknownError
        }
    }
}
