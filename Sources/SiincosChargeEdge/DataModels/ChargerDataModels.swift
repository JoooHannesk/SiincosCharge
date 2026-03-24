//
//  ChargerModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 23.03.26.
//

import ModbusSerial
import Foundation

/// Generic Car Charger
///
/// This describes a generic car charger. Every car charger needs to implement these
/// functions to work within the SiincosCharge infrastructure
protocol CarCharger {
    var modbusDevice: ModbusRTUClient { get }
    var unitId: UInt8 { get }
    init(modbusDevice: ModbusRTUClient, unitId: UInt8)
    func getChargingState() async throws -> ChargerState
    func getInternalTemperature() async throws -> Measurement<UnitTemperature>
    func getHardwareCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>>
    func getMaxCurrentLimitSetpoint() async throws -> Measurement<UnitElectricCurrent>
    @discardableResult func setMaxCurrentLimitSetpoint(to: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent>
    func getHardwareLockState() async throws -> LockState
    func getSoftwareLockState() async throws -> LockState
    func setSoftwareLock(to: LockState) async throws -> LockState
}

/// Generic Power Meter
///
/// This describes a generic power meter. Every power meter needs to implement these
/// functions to work within the SiincosCharge infrastructure
protocol PowerMeter {
    var modbusDevice: ModbusRTUClient { get }
    var unitId: UInt8 { get }
    init(modbusDevice: ModbusRTUClient, unitId: UInt8)
    func getElectricCurrent() -> ElectricCurrent3PhaseGrid
    func getGridVoltage() -> ElectricVoltage3PhaseGrid
    func getPower() -> ElectricPower3PhaseGrid
    func getTotalEnergy() -> Measurement<UnitEnergy>
}

/// Generic Car Charger States
///
enum ChargerState {

    case unknown

    // vehicle not present
    case vehicleNotPresentChargerReady
    case vehicleNotPresentChargerNotReady

    // vehicle present no charging request
    case vehiclePresentNoRequestChargerReady
    case vehiclePresentNoRequestChargerNotReady

    // vehicle present charging request
    case vehiclePresentRequestChargerReady
    case vehiclePresentRequestChargerNotReady

    // other states
    case chargingDerated
    case e // TODO: check status name and description
    case f // TODO: check status name and description
    case chargingError
}

/// Lock States
///
/// States representing a generic lock
enum LockState {
    case locked
    case unlocked
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
struct Boundaries<T: Comparable> {
    let minimal: T
    let maximal: T

    init(minimal: T, maximal: T) throws(ChargerError) {
        self.minimal = minimal
        self.maximal = maximal
        if minimal > maximal {
            throw ChargerError.boundaryViolation
        }
    }
}

/// Car Charger Errors
/// 
enum ChargerError: Error {
    case boundaryViolation
}
