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

    /// System total maximum current
    ///
    /// Defines the maximum possible current drawn from the power grid (given in amperes) for the local installation.
    let systemTotalMaxCurrent: Measurement<UnitElectricCurrent>

    /// Load balanced maxminum current
    ///
    /// When more than one charger is connected, the system has to ensure that the total current drawn from
    /// all EV chargers stays below the ``systemTotalMaxCurrent``. Therefor each charging point is limited to
    /// the ``loadBalancedMaxCurrent`` (given in amperes).
    let loadBalancedMaxCurrent: Measurement<UnitElectricCurrent>

    /// Init a Charging System
    ///
    /// - Parameter config: Provide device configuration to setup communication for EV chargers and smart meters
    init(config: DeviceConfig) {
        self.systemTotalMaxCurrent = Measurement(value: Double(config.lineMaxCurrentA), unit: UnitElectricCurrent.amperes)
        self.loadBalancedMaxCurrent = Measurement(value: 0.0, unit: UnitElectricCurrent.amperes)
    }

    func getEvState(chargerUnitId: UInt8) -> EVState {
        #warning("Implement")
        return .unplugged
    }

    func getChargingState(chargerUnitId: UInt8) -> ChargerState {
        #warning("Implement")
        return .charging
    }

    func getChargingPermission(chargerUnitId: UInt8) -> Status {
        #warning("Implement")
        return .disabled
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
