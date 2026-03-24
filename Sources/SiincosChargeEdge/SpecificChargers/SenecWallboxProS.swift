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

    init(modbusDevice: ModbusRTUClient, unitId: UInt8) {
        self.modbusDevice = modbusDevice
        self.unitId = unitId
    }
    
    func getChargingState() async throws -> ChargerState {
        let response = try await self.modbusDevice.readInputRegisters(address: 5, count: 1, unitId: self.unitId)
        let state = response.signedValue(at: 0)
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
    
    func getInternalTemperature() async throws -> Measurement<UnitTemperature> {
        // TODO: implement
        return Measurement(value: 0.0, unit: UnitTemperature.celsius)
    }
    
    func getHardwareCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>> {
        // TODO: implement
        let min = Measurement(value: 6, unit: UnitElectricCurrent.amperes)
        let max = Measurement(value: 16, unit: UnitElectricCurrent.amperes)
        return try Boundaries(minimal: min, maximal: max)
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
