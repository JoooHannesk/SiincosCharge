//
//  ChargingSystem.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 14.05.26.
//

import Foundation


/// Charging System
///
/// A Charging System represents a local EV charging installation consisting of multiple charging
/// points connected to and controlled by a single Siincos Charge Edge Gateway.
///
/// A single Charging System is represented as a single device in the IoT cloud.
final class ChargingSystem {

    /// System total maximal current
    ///
    /// Defines the maximum possible current drawn from the power grid (given in amperes) for the local installation.
    let systemTotalMaxCurrent: UInt8

    /// Init a Charging System
    ///
    /// - Parameter config: Provide device configuration to setup communication for EV chargers and smart meters
    init(config: DeviceConfig) {
        self.systemTotalMaxCurrent = config.lineMaxCurrentA
    }

    func getEvState(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func getChargingState(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func getChargingPermission(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func enableCharging(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func disableCharging(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func getChargingCurren(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func setChargingCurrent(to current: Measurement<UnitElectricCurrent>, for chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func getMeterReading(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func getChargingPower(chargerUnitId: UInt8) {
        #warning("Implement")
    }

    func getGridVoltage(chargerUnitId: UInt8) {
        #warning("Implement")
    }
}
