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
            throw DeviceError.deviceDataMissing
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
    /// Retrieve internal system temperature from charger
    ///
    /// - Returns: internal system temperature as ``Measurement<UnitTemperature>``
    /// - Note: Refers to register address 9 in corresponding modbus mapping
    func getInternalTemperature() async throws -> Measurement<UnitTemperature> {
        let response = try await self.modbusDevice.readInputRegisters(address: 9, count: 1, unitId: self.unitId)
        guard let temperatureValue = response.signedValue(at: 0) else {
            throw DeviceError.deviceDataMissing
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
            throw DeviceError.deviceDataMissing
        }
        return try Boundaries(minimal: Measurement(value: Double(minimalCurrentValue), unit: UnitElectricCurrent.amperes),
                              maximal: Measurement(value: Double(maximalCurrentValue), unit: UnitElectricCurrent.amperes))
    }

    func getMaxCurrentLimitSetpoint() async throws -> Measurement<UnitElectricCurrent> {
        // TODO: implement
        return Measurement(value: 16, unit: UnitElectricCurrent.amperes)
    }

    func setMaxCurrentLimitSetpoint(to: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent> {
        // TODO: implement
        return Measurement(value: 16, unit: UnitElectricCurrent.amperes)
    }

    func getHardwareLockState() async throws -> LockState {
        // TODO: implement
        return .locked
    }
    
    func getSoftwareLockState() async throws -> LockState {
        // TODO: implement
        return .locked
    }
    
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
