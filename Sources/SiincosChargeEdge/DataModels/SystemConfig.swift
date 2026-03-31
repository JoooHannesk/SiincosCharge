//
//  SystemConfig.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 31.03.26.
//

struct SystemConfig: CustomStringConvertible {
    let systemId: String
    let chargerModel: CompatibleCharger
    let chargerBus: String
    let meterModel: CompatibleCharger
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
