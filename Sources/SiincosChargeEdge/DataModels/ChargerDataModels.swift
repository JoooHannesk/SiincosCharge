//
//  ChargerModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 23.03.26.
//

import ModbusSerial
import Foundation


/// Generic ModbusRTU Device
///
/// Generic Modbus RTU device attached to the bus line
protocol ModbusRTUDevice: Sendable {

    /// Initializer
    ///
    /// Instance requires a modbus rtu client and a specific unit id to
    /// communicate on the bus system
    /// - Parameters:
    ///    - modbusRTUClient: Configured modbus rtu client
    ///    - unitId: Device unit id on the modbus rtu bus
    init(modbusRTUClient: ModbusRTUClient, unitId: UInt8)
}

/// Generic EV Charger
///
/// This describes a generic car charger. Every car charger needs to implement these
/// functions to work within the SiincosCharge infrastructure
protocol EVCharger: Sendable {

    /// Unit ID
    ///
    /// Unique id for identifying the device and its data within the local infrastructure.
    /// Power meters ``PowerMeter`` and car chargers ``ChargingSystem`` belonging logically togehter
    /// and therefore have to share the same unit id. (Both are lockated on two different RS485 lines and transceivers).
    var unitId: UInt8 { get }

    /// Setup Configuration
    ///
    /// Setup device by loading device specific default configuration which
    /// is required for proper operation
    func setupConfig() async throws

    /// Get Charging State
    ///
    /// Retrieve the charger state from device
    ///
    /// - Returns: ``ChargerState``
    func getChargerState() async throws -> ChargerState

    /// Get EV Plugged State
    ///
    /// Retrieve the current EV Plugged State
    /// - Returns: ``EVState``
    func getEVPluggedState() async throws -> EVState

    /// Get Internal Temperature
    ///
    /// Retrieve internal system temperature from charger. Required for monitoring and system health diagnosis.
    ///
    /// - Returns: internal system temperature
    func getInternalTemperature() async throws -> Measurement<UnitTemperature>

    /// Get Hardware Current Limits
    ///
    /// The charger is bound to specific electric current limits, constraint by the overall hardware design and the installation limits.
    /// These limits are required to ensure proper system functionality such as load balancing, equal current distribution, etc.
    ///
    /// - Returns: Current limites (given by hardware and/or installation)
    func getHardwareCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>>

    /// Get Max Current Limit Setpoint
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle. This function retrieves the
    /// current setpoint from the charger and returns it.
    ///
    /// - Returns: acutal electrical current setpoint
    func getMaxCurrentLimitSetpoint() async throws -> Measurement<UnitElectricCurrent>

    /// Set Max Current Limit Setpoint
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle. This function sets the
    /// maximum current setpoint in the charger.
    ///
    /// - Parameter setpoint: Current limit setpoint to transfer to the charger
    /// - Returns: Acutal electrical current setpoint as type, processed by the charger.
    /// - Note: In case the provided current setpoint exceeds the maximum hardware current limit, the hardware specific limit is transferred to the charger.
    @discardableResult func setMaxCurrentLimitSetpoint(to setpoint: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent>

    /// Get Hardware Lock State
    ///
    /// Some chargers have a phyiscal hardware lock which is required to be unlocked manually before a charging session can be started. This
    /// function returns the actual hardware lock state.
    ///
    /// - Returns: lock state as type ``LockState``
    /// - Note: In case a charger has no physical hardware lock, this function returns .unavailable
    func getHardwareLockState() async throws -> LockState

    /// Get Software Lock State
    ///
    /// Chargers need to have a software lock which is required to be unlocked before a charging session can be started. This
    /// function returns the actual lock state. Refer to ``EVCharger/setSoftwareLock(to:)`` for unlocking the
    /// software lock.
    ///
    /// - Returns: lock state as type ``LockState``
    func getSoftwareLockState() async throws -> LockState

    /// Set Software Lock State
    ///
    /// Chargers need to have a software lock which is required to be unlocked before a charging session can be started. This
    /// function unlocks the software lock.
    ///
    /// - Returns: lock state as type ``LockState``, processed by the charger.
    func setSoftwareLock(to: LockState) async throws -> LockState
}


/// Generic Power Meter
///
/// This describes a generic power meter. Every power meter needs to implement these
/// functions to work within the SiincosCharge infrastructure.
/// Power meter and charger are separated in case an external, dedicated power meter is used
protocol PowerMeter: Sendable {

    /// Unit ID
    ///
    /// Unique id for identifying the device and its data within the local infrastructure.
    /// Power meters and car chargers belonging logically togehter have to share the same unit id.
    var unitId: UInt8 { get }

    /// Get Electric Current
    ///
    /// Return electric current drawn by the EV.
    /// - Returns: Electric current for a 3-phase grid
    func getElectricCurrent() async throws -> ElectricCurrent3PhaseGrid

    /// Get Grid Voltage
    ///
    /// Return electric grid voltage.
    /// - Returns: electric voltage provided by the 3-phase power grid.
    func getGridVoltage() async throws -> ElectricVoltage3PhaseGrid

    /// Get Electric Power
    ///
    /// Return electric power drawn by the EV.
    /// - Returns: Electric power drawn by the EV for a 3-phase power grid
    func getElectricPower() async throws -> ElectricPower3PhaseGrid

    /// Get Electric Energy (total)
    ///
    /// Return total energy provided by the EV charger (energy since installation).
    /// - Returns: Total energy provided by the EV charger since installation
    func getElectricEnergy() async throws -> Measurement<UnitEnergy>
}

/// Harmonized Charger States
///
/// Siincos Charge Edge supports the following harmonized charger states.
enum ChargerState {

    /// EV is charging
    case charging

    /// EV is not charging
    case notCharging

    /// Charger state is unknown
    case unknown

    /// Charger encountered an error
    case error
}

/// Harmonized EV States
///
/// Siincos Charge Edge supports the following harmonized EV states.
enum EVState {

    /// EV is plugged into charger
    case pluggedIn

    /// EV is not plugged into charger
    case unplugged

    /// EV state is unknown (not good, but we may need this state)
    case unknown

    /// Unclear, as it is either plugged or unplugged, but leave this case
    /// for some sort of communication error between charger and EV
    case error

}

/// Lock States
///
/// States representing a generic lock
enum LockState: UInt {
    case locked = 0
    case unlocked = 1
    case unknown = 2
}

/// Status
///
/// Represent a simple status: `.enabled` or `.disabled` and `.unknown`
/// if not supported by a device or functionality
enum Status: UInt8 {
    case enabled
    case disabled
    case unknown
}

/// Electric Current
///
/// Electric current in a 3-phase grid
struct ElectricCurrent3PhaseGrid {
    var currentL1: Measurement<UnitElectricCurrent>?
    var currentL2: Measurement<UnitElectricCurrent>?
    var currentL3: Measurement<UnitElectricCurrent>?
}

/// Electric Voltage
///
/// Electric voltage in a 3-Phase grid
struct ElectricVoltage3PhaseGrid {
    var voltageL1: Measurement<UnitElectricPotentialDifference>?
    var voltageL2: Measurement<UnitElectricPotentialDifference>?
    var voltageL3: Measurement<UnitElectricPotentialDifference>?
}

/// Electric Power
///
/// Electric power in a 3-phase grid
struct ElectricPower3PhaseGrid {
    var powerL1: Measurement<UnitPower>?
    var powerL2: Measurement<UnitPower>?
    var powerL3: Measurement<UnitPower>?
    var powerTotal: Measurement<UnitPower>?
}

/// Boundary
///
/// Boundary consisting of a minimal and maximal value
struct Boundaries<T: Comparable>: CustomStringConvertible {
    var description: String {
        return "Minimal Value: \(minimal) < Maximal Value: \(maximal)"
    }

    let minimal: T
    let maximal: T

    init(minimal: T, maximal: T) throws(SystemError) {
        self.minimal = minimal
        self.maximal = maximal
        if minimal > maximal {
            throw SystemError.boundaryViolation
        }
    }
}
