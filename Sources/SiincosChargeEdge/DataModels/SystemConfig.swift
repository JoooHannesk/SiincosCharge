//
//  SystemConfig.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//

protocol DeviceConfig {
    var systemId: String { get }
    var chargerModel: CompatibleCharger { get }
    var chargerBus: String { get }
    var meterModel: CompatiblePowerMeter { get }
    var meterBus: String { get }
    var lineLength: UInt8 { get }
}

protocol CloudConfig {
    var cloudHost: String { get }
    var cloudPort: UInt16 { get }
    var cloudCACertPath: String { get }
    var cloudClientId: String { get }
    var cloudUsername: String { get }
    var cloudPassword: String { get }
}

/// System Configuration
///
/// System configuration for the Siincos Charge Edge system
struct SystemConfig: DeviceConfig, CloudConfig, Codable, CustomStringConvertible {
    let systemId: String
    let chargerModel: CompatibleCharger
    let chargerBus: String
    let meterModel: CompatiblePowerMeter
    let meterBus: String
    let lineLength: UInt8
    let lineMaxCurrentA: UInt8
    let cloudHost: String
    let cloudPort: UInt16
    let cloudCACertPath: String
    let cloudClientId: String
    let cloudUsername: String
    let cloudPassword: String

    var description: String {
        return "System ID: \(self.systemId), Charger Model: \(self.chargerModel), Charger Bus: \(self.chargerBus), Meter Model: \(self.meterModel), Meter Bus: \(self.meterBus), Line Length: \(self.lineLength), Line Max Current: \(self.lineMaxCurrentA), Cloud: \(self.cloudHost):\(self.cloudPort)"
    }
}
