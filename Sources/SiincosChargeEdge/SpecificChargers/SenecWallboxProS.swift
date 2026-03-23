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
        var response = try await self.modbusDevice.readInputRegisters(address: 5, count: 1, unitId: self.unitId)
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
    }
    
    func getHardwareCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>> {
        // TODO: implement
    }

    func getMaxCurrentLimitSetpoint() async throws -> Measurement<UnitElectricCurrent> {
        // TODO: implement
    }

    func setMaxCurrentLimitSetpoint(to: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent> {
        // TODO: implement
    }

    func getHardwareLockState() async throws -> LockState {
        // TODO: implement
    }
    
    func getSoftwareLockState() async throws -> LockState {
        // TODO: implement
    }
    
    func setSoftwareLock(to: LockState) async throws -> LockState {
        // TODO: implement
    }

    // MARK: Device specific functionality
    func getPowerSavingMode() -> Bool {
        // refered to as standby mode in modbus mapping manual
        // TODO: implement
    }

    func setPowerSavingMode(to: Bool) {
        // refered to as standby mode in modbus mapping manual
        // TODO: implement
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
        <#code#>
    }
    
    func getGridVoltage() -> ElectricVoltage3PhaseGrid {
        <#code#>
    }
    
    func getPower() -> ElectricPower3PhaseGrid {
        <#code#>
    }
    
    func getTotalEnergy() -> Measurement<UnitEnergy> {
        <#code#>
    }
}
