//
//  SenecWallboxProS.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 23.03.26.
//

import Foundation
import ModbusSerial

/// Senec Wallbox Pro S
///
/// Senec Wallbox Pro S as modbus device
struct SenecWallboxProS: CarCharger {
    let modbusDevice: ModbusRTUClient
    let unitId: UInt8

    /// Initializer
    ///
    /// Instance requires a modbus client configuration and the specific unit id on the bus system
    ///
    /// - Parameters:
    ///    - modbusDevice: Configured modbus client, connected
    ///    - unitId: Device unit id on the modbus bus
    init(modbusDevice: ModbusRTUClient, unitId: UInt8) {
        self.modbusDevice = modbusDevice
        self.unitId = unitId
    }

    /// Get Charging State
    ///
    /// Retrieve the charger state from device
    ///
    /// - Returns: ``ChargerState``
    /// - Note: Refers to register address 5 in corresponding modbus mapping
    func getChargingState() async throws -> ChargerState {
        let response = try await self.modbusDevice.readInputRegisters(address: 5, count: 1, unitId: self.unitId)
        guard let state = response.signedValue(at: 0) else {
            throw DeviceError.dataMissing
        }
        switch state {
        case 2:
            return .vehicleNotPresentChargerNotReady
        case 3:
            return .vehicleNotPresentChargerReady
        case 4:
            return .vehiclePresentNoRequestChargerNotReady
        case 5:
            return .vehiclePresentNoRequestChargerReady
        case 6:
            return .vehiclePresentRequestChargerNotReady
        case 7:
            return .vehiclePresentRequestChargerReady
        case 8:
            return .chargingDerated
        case 9:
            return .e
        case 10:
            return .f
        case 11:
            return .chargingError
        default:
            return .unknown
        }
    }

    /// Get Internal Temperature
    ///
    /// Retrieve internal system temperature from charger. Required for monitoring and system health diagnosis.
    ///
    /// - Returns: internal system temperature as ``Measurement<UnitTemperature>``
    /// - Note: Refers to register address 9 in corresponding modbus mapping
    func getInternalTemperature() async throws -> Measurement<UnitTemperature> {
        let response = try await self.modbusDevice.readInputRegisters(address: 9, count: 1, unitId: self.unitId)
        guard let temperatureValue = response.signedValue(at: 0) else {
            throw DeviceError.dataMissing
        }
        let temperature = Double(temperatureValue)/10.0
        return Measurement(value: temperature, unit: UnitTemperature.celsius)
    }

    /// Get Hardware Current Limits
    ///
    /// The charger is bound to specific electric current limits, given by the overall hardware design and the installation limits.
    /// These limits are required to ensure proper system functionality such as load balancing, equal current distribution, etc.
    ///
    /// - Returns: Current limites (given by hardware and/or installation) as type ``Boundaries<Measurement<UnitElectricCurrent>>``
    /// - Note: Refers to register addresses 100 and 101 in corresponding modbus mapping
    func getHardwareCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>> {
        let responseMinimalCurrent = try await self.modbusDevice.readInputRegisters(address: 101, count: 1, unitId: self.unitId)
        let responseMaximalCurrent = try await self.modbusDevice.readInputRegisters(address: 100, count: 1, unitId: self.unitId)
        guard let minimalCurrentValue = responseMinimalCurrent.signedValue(at: 0), let maximalCurrentValue = responseMaximalCurrent.signedValue(at: 0)  else {
            throw DeviceError.dataMissing
        }
        return try Boundaries(minimal: Measurement(value: Double(minimalCurrentValue), unit: UnitElectricCurrent.amperes),
                              maximal: Measurement(value: Double(maximalCurrentValue), unit: UnitElectricCurrent.amperes))
    }

    /// Get Max Current Limit Setpoint
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle. This function retrieves the
    /// current setpoint from the charger and returns it.
    ///
    /// - Returns: acutal electrical current setpoint as type ``Measurement<UnitElectricCurrent>``
    /// - Note: Refers to register address 261 in corresponding modbus mapping. This value is not retained in the charger and
    /// will not survive a power cylce!
    func getMaxCurrentLimitSetpoint() async throws -> Measurement<UnitElectricCurrent> {
        let responseCurrentSetpoint = try await self.modbusDevice.readHoldingRegisters(address: 261, count: 1, unitId: self.unitId)
        guard var responseCurrentSetpointValue = responseCurrentSetpoint.signedValue(at: 0) else {
            throw DeviceError.dataMissing
        }
        responseCurrentSetpointValue /= 10 // Required per modbus documentation
        return Measurement(value: Double(responseCurrentSetpointValue), unit: UnitElectricCurrent.amperes)
    }

    /// Set Max Current Limit Setpoint
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle. This function sets the
    /// maximum current setpoint in the charger.
    ///
    /// - Parameter setpoint: Current limit setpoint to transfer to the charger (as type ``Measurement<UnitElectricCurrent>``).
    /// - Returns: Acutal electrical current setpoint as type ``Measurement<UnitElectricCurrent>``, processed by the charger.
    /// - Note: In case the provided current setpoint exceeds the maximum hardware current limit, the hardware specific limit is transferred to the charger. Refers
    /// to register address 261 in corresponding modbus mapping. This value is not retained in the cahrger and will not survive a power cylce!
    func setMaxCurrentLimitSetpoint(to setpoint: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent> {
        let hardwareLimits = try await self.getHardwareCurrentLimits()
        // ensure to not exceed the hardware current constraints
        let newSetpoint = max(min(setpoint, hardwareLimits.maximal), hardwareLimits.minimal)
        // Factory required per modbus documentation
        let newSetpointInt = UInt16(newSetpoint.value * 10)
        let _ = try await self.modbusDevice.writeMultipleRegisters(address: 261, values: [newSetpointInt], unitId: self.unitId)
        let newSetpointProcessedByCharger = try await self.getMaxCurrentLimitSetpoint()
        return newSetpointProcessedByCharger
    }

    /// Get Hardware Lock State
    ///
    /// Some chargers have a phyiscal hardware lock which is required to be unlocked manually before a charging session can be started. This
    /// function returns the actual hardware lock state.
    ///
    /// - Returns: lock state as type ``LockState``
    /// - Note: Refers to register address 13 in corresponding modbus mapping.
    func getHardwareLockState() async throws -> LockState {
        let lockState = try await self.modbusDevice.readInputRegisters(address: 13, count: 1, unitId: self.unitId)
        guard let lockStateValue = lockState.signedValue(at: 0) else {
            throw DeviceError.dataMissing
        }
        return LockState(rawValue: UInt(lockStateValue)) ?? .unknown
    }

    /// Get Software Lock State
    ///
    /// Chargers need to have a software lock which is required to be unlocked before a charging session can be started. This
    /// function returns the actual lock state. Refer to ``SenecWallboxProS/setSoftwareLock(to:)`` for unlocking the
    /// software lock.
    ///
    /// - Returns: lock state as type ``LockState``
    /// - Note: Refers to register address 259 in corresponding modbus mapping.
    func getSoftwareLockState() async throws -> LockState {
        let lockState = try await self.modbusDevice.readHoldingRegisters(address: 259, count: 1, unitId: self.unitId)
        guard let lockStateValue = lockState.signedValue(at: 0) else {
            throw DeviceError.dataMissing
        }
        return LockState(rawValue: UInt(lockStateValue)) ?? .unknown
    }

    /// Set Software Lock State
    ///
    /// Chargers need to have a software lock which is required to be unlocked before a charging session can be started. This
    /// function unlocks the software lock.
    ///
    /// - Returns: lock state as type ``LockState``
    /// - Note: Refers to register address 259 in corresponding modbus mapping.
    func setSoftwareLock(to: LockState) async throws -> LockState {
        // TODO: implement
        return .locked
    }

    // MARK: Device specific functionality
    func getPowerSavingMode() -> Bool {
        // refered to as standby mode in modbus mapping manual
        // TODO: implement
        return false
    }

    func setPowerSavingMode(to: Bool) -> Bool {
        // refered to as standby mode in modbus mapping manual
        // TODO: implement
        return false
    }

    func getModbusWatchdogTimeout() {
        // TODO: implement
    }

    func setModbusWatchdogTimeout(to: Int) {
        // TODO: implement
    }

    func getCommFailureMaxCurrent() {
        // TODO: implement
    }

    func setCommFailureMaxCurrent() {
        // TODO: implement
    }

}

/// Power Meter inside Senec Wallbox Pro S
///
/// Senec Wallbox Pro S has an integrated power meter.
/// - Note: Power meter and charger are separated in case an external,
/// dedicated power meter is used
struct SenecWallboxProSPowerMeter: PowerMeter {
    let modbusDevice: ModbusSerial.ModbusRTUClient
    let unitId: UInt8

    init(modbusDevice: ModbusRTUClient, unitId: UInt8) {
        self.modbusDevice = modbusDevice
        self.unitId = unitId
    }

    func getElectricCurrent() -> ElectricCurrent3PhaseGrid {
        // TODO: implement
        return ElectricCurrent3PhaseGrid()
    }
    
    func getGridVoltage() -> ElectricVoltage3PhaseGrid {
        // TODO: implement
        return ElectricVoltage3PhaseGrid()
    }
    
    func getPower() -> ElectricPower3PhaseGrid {
        // TODO: implement
        return ElectricPower3PhaseGrid()
    }
    
    func getTotalEnergy() -> Measurement<UnitEnergy> {
        // TODO: implement
        return Measurement(value: 0, unit: UnitEnergy.kilowattHours)
    }
}
