//
//  ChargingSystem.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 14.05.26.
//


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

    func getChargingState() {
        #warning("Implement")
    }

    func getEvState() {
        #warning("Implement")
    }

    func getMeterReading() {
        #warning("Implement")
    }

    func getChargingCurren() {
        #warning("Implement")
    }

    func getChargingPower() {
        #warning("Implement")
    }

    func getGridVoltage() {
        #warning("Implement")
    }

    func enableCharging() {
        #warning("Implement")
    }

    func disableCharging() {
        #warning("Implement")
    }

    func setChargingCurrent() {
        #warning("Implement")
    }

}
