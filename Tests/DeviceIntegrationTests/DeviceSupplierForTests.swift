//
//  DeviceSupplierForTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 04.04.26.
//


import Testing
@testable import SiincosChargeEdge


enum DeviceSupplierForTests {

    static func getSpecificCharger<T>() -> T? {
        var charger: T? = nil
        do {
            let systemConfig = try ComponentSupplier.getSystemConfig()
            let devices = try ComponentSupplier.getDevices(for: systemConfig)
            charger = devices.0.first as? T
        } catch {
            Issue.record("Unable to get system configuration: \(error.localizedDescription)")
        }
        return charger
    }
    
}
