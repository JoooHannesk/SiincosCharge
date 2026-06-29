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

    /// Hold all charging points
    let chargingPointContainer: ChargingPointContainer

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
    init(config: DeviceConfig) async throws {
        self.chargingPointContainer = try await Self.collectChargingPoints(basedOn: config)
        self.systemTotalMaxCurrent = Measurement(value: Double(config.lineMaxCurrentA), unit: UnitElectricCurrent.amperes)
        self.loadBalancedMaxCurrent = Measurement(value: 0.0, unit: UnitElectricCurrent.amperes)
    }

    /// Get EV State
    ///
    /// Get EV plugged in state.
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: ``EVState``
    func getEvState(chargingPointId: UInt8) async throws -> EVState {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let evState = try await chargingPoint?.evState
        return evState ?? .unknown
    }

    /// Get Charging State
    ///
    /// Get EV charging state
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: ``ChargerState``
    func getChargingState(chargingPointId: UInt8) async throws -> ChargerState {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let chargingState = try await chargingPoint?.chargingState
        return chargingState ?? .unknown
    }

    /// Get Charging Permission
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: Charging permission for given charging point ``Status``
    func getChargingPermission(chargingPointId: UInt8) async -> Status {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let chargingPermission = await chargingPoint?.chargingPermission
        return chargingPermission ?? .unknown
    }

    /// Set Charging Permission
    ///
    /// - Parameters:
    ///    - chargingPermission: Charging permission either granted (`.enabled`) or denied (`.disabled`)
    ///    - chargingPointId: ChargingPoint Id
    /// - Returns: Actual charging permission returned by charging point for provided charging point id
    func setChargingPermission(to chargingPermission: Status, for chargingPointId: UInt8) async throws -> Status {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        var newChargingPermission: Status = .unknown
        if chargingPermission == .enabled {
            newChargingPermission = try await chargingPoint?.enableCharging() ?? .unknown
        } else if chargingPermission == .disabled {
            newChargingPermission = try await chargingPoint?.disableCharging() ?? .unknown
        }
        return newChargingPermission
    }

    /// Get Charging Current Setpoint
    ///
    /// Charging current setpoint currently active in ev charger
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: Charging current setpoint for given charging point
    func getChargingCurrenSetpoint(chargingPointId: UInt8) async throws -> Measurement<UnitElectricCurrent> {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let currentSetpoint = try await chargingPoint?.chargingCurrentSetpoint
        return currentSetpoint ?? Measurement(value: 0.0, unit: UnitElectricCurrent.amperes)
    }

    /// Set Charging Current Setpoint
    ///
    /// Transfer charging current setpoint to charging point
    ///
    /// - Parameters:
    ///    - current: Maximum current setpoint allowed to draw from EV charging point
    ///    - chargingPointId: ChargingPoint Id
    /// - Returns: Actual charging current setpoint for given charging point
    func setChargingCurrentSetpoint(to current: Measurement<UnitElectricCurrent>, for chargingPointId: UInt8) async throws -> Measurement<UnitElectricCurrent> {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let currentSetpoint = try await chargingPoint?.setChargingCurrentSetpoint(to: current)
        return currentSetpoint ?? Measurement(value: 0.0, unit: UnitElectricCurrent.amperes)
        // TODO: ensure that charging current load balancing / load limitting is done properly!
    }

    /// Get charging current
    ///
    /// Get realtime EV charging current for provided charging point id
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: Realtime charging current for given charging point ``ElectricCurrent3PhaseGrid``
    func getChargingCurrent(chargingPointId: UInt8) async throws -> ElectricCurrent3PhaseGrid {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let chargingCurrent = try await chargingPoint?.chargingCurrent
        return chargingCurrent ?? ElectricCurrent3PhaseGrid()
    }

    /// Get Meter Reading
    ///
    /// Get Power Meter reading for given charging point Id
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: Power Meter reading for provided charging point
    func getMeterReading(chargingPointId: UInt8) async throws -> Measurement<UnitEnergy> {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let meterReading = try await chargingPoint?.meterReading
        return meterReading ?? Measurement(value: 0.0, unit: UnitEnergy.kilowattHours)
    }

    /// Get Charging Power
    ///
    /// Get realtime EV charging power for provided charging point id
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: Realtime charging power for given charging point ``ElectricPower3PhaseGrid``
    func getChargingPower(chargingPointId: UInt8) async throws -> ElectricPower3PhaseGrid {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let chargingPower = try await chargingPoint?.chargingPower
        return chargingPower ?? ElectricPower3PhaseGrid(powerTotal: Measurement(value: 0.0, unit: UnitPower.watts))
    }

    /// Get Grid Voltage
    ///
    /// Get realtime grid voltage for provided charging point id
    ///
    /// - Parameter chargingPointId: ChargingPoint Id
    /// - Returns: Realtime voltage for given charging point ``ElectricVoltage3PhaseGrid``
    func getGridVoltage(chargingPointId: UInt8) async throws -> ElectricVoltage3PhaseGrid {
        let chargingPoint = await self.chargingPointContainer.getChargingPoint(by: chargingPointId)
        let gridVoltage = try await chargingPoint?.gridVoltage
        return gridVoltage ?? ElectricVoltage3PhaseGrid()
    }

    /// Collect Charging Points
    ///
    /// Take ``DeviceConfig`` and collect the charging points accordingly.
    ///
    /// - Parameter deviceConfig: Device config containing the charging point information
    /// - Returns: a ``ChargingPointContainer`` instance containing all charging points described in the given ``DeviceConfig``
    static func collectChargingPoints(basedOn deviceConfig: DeviceConfig) async throws -> ChargingPointContainer {
        let chargingPoints = ChargingPointContainer()
        let devices = try ComponentSupplier.getDevices(for: deviceConfig)
        for (evCharger, powerMeter) in zip(devices.evChargers, devices.powerMeters) {
            let chargingPoint = try await ChargingPoint(evCharger: evCharger, powerMeter: powerMeter)
            await chargingPoints.addChargingPoint(chargingPoint)
        }
        return chargingPoints
    }
}
