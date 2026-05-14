//
//  JanitzaSmartMeterB2331210J.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 13.05.26.
//

import Foundation
import ModbusSerial


/// Janitza Smart Meter B23 312-10J
///
/// Janitza Smart Meter B23 312-10J as Modbus RTU device
struct JanitzaSmartMeterB2331210J: PowerMeter, ModbusRTUDevice {

    static let logger = ComponentSupplier.mainLogger

    static func getModbusDeviceClient(serialPort: String) -> ModbusRTUClient {
        let config = RTUClientConfiguration(
            serialConfiguration: SerialConfiguration(
                port: serialPort,
                baudRate: .b19200,
                parity: .even,
                stopBits: .one,
                dataBits: .eight,
                timeout: .seconds(3)
            ),
            retries: 3,
            errorRecovery: .exponentialBackoff(
                initialDelay: .milliseconds(500),
                maxDelay: .seconds(10)
            ),
            handleLocalEcho: false  // For RS-485 half-duplex adapters
        )
        return ModbusRTUClient(configuration: config)
    }

    let modbusDevice: ModbusRTUClient
    let unitId: UInt8
    let modelName: SupportedPowerMeter

    /// Initializer
    ///
    /// Instance requires a modbus client configuration, the specific unit id on the bus system
    /// and the specific device model name
    ///
    /// - Parameters:
    ///    - modbusRTUClient: Configured modbus client, connected
    ///    - unitId: Device unit id on the modbus bus
    ///    - modelName: Specific device model name for better identification
    init(modbusRTUClient: ModbusSerial.ModbusRTUClient, unitId: UInt8, modelName: String) {
        self.modbusDevice = modbusRTUClient
        self.unitId = unitId
        self.modelName = SupportedPowerMeter.init(rawValue: modelName) ?? .unknown
    }

    /// Get Electric Current
    ///
    /// Return electric current drawn by the EV.
    /// - Returns: Electric current drawn by the EV on a 3-phase grid
    /// - Note: Refers to the following register addresses in corresponding modbus mapping:
    ///     * L1: Registers 23308, 23309
    ///     * L2: Registers 23310, 23311
    ///     * L3: Registers 23312, 23313
    func getElectricCurrent() async throws -> ElectricCurrent3PhaseGrid {
        let il1 = try await self.modbusDevice.readHoldingRegisters(address: 23308, count: 2, unitId: self.unitId)
        let il2 = try await self.modbusDevice.readHoldingRegisters(address: 23310, count: 2, unitId: self.unitId)
        let il3 = try await self.modbusDevice.readHoldingRegisters(address: 23312, count: 2, unitId: self.unitId)

        guard let il1Value = il1.uint32Value(at: 0),
              let il2Value = il2.uint32Value(at: 0),
              let il3Value = il3.uint32Value(at: 0) else {
            throw SystemError.dataMissing
        }
        let currentDrawn = ElectricCurrent3PhaseGrid(
            currentL1: Measurement(value: Double(il1Value)/100, unit: UnitElectricCurrent.amperes),
            currentL2: Measurement(value: Double(il2Value)/100, unit: UnitElectricCurrent.amperes),
            currentL3: Measurement(value: Double(il3Value)/100, unit: UnitElectricCurrent.amperes)
        )
        return currentDrawn
    }

    /// Get Electric Grid Voltage
    ///
    /// Return electric voltage provided by the power grid.
    /// - Returns: Electric voltage for a 3-phase grid
    /// - Note: Refers to the following register addresses in the corresponding modbus mapping:
    ///     * L1: Registers 23296, 23297
    ///     * L2: Registers 23298, 23299
    ///     * L3: Registers 23300, 23301
    func getGridVoltage() async throws -> ElectricVoltage3PhaseGrid {
        let ul1 = try await self.modbusDevice.readHoldingRegisters(address: 23296, count: 2, unitId: self.unitId)
        let ul2 = try await self.modbusDevice.readHoldingRegisters(address: 23298, count: 2, unitId: self.unitId)
        let ul3 = try await self.modbusDevice.readHoldingRegisters(address: 23300, count: 2, unitId: self.unitId)

        guard let ul1Value = ul1.uint32Value(at: 0),
              let ul2Value = ul2.uint32Value(at: 0),
              let ul3Value = ul3.uint32Value(at: 0) else {
            throw SystemError.dataMissing
        }
        let gridVoltage3phase = ElectricVoltage3PhaseGrid(
            voltageL1: Measurement(value: Double(ul1Value)/10, unit: UnitElectricPotentialDifference.volts),
            voltageL2: Measurement(value: Double(ul2Value)/10, unit: UnitElectricPotentialDifference.volts),
            voltageL3: Measurement(value: Double(ul3Value)/10, unit: UnitElectricPotentialDifference.volts)
        )
        return gridVoltage3phase
    }

    /// Get Electric Power
    ///
    /// Get electric power drawn from EV charger and delivered by grid: Active Power
    /// This power meter provides the total power (L1+L2+L3) and the power per phase in
    /// individual registers.
    ///
    /// - Returns: Electric power currently drawn by the EV (power for a 3-phase power grid).
    /// - Note: Refers to the following register addresses in the corresponding modbus mapping:
    ///     * L1: Registers 23318, 23319
    ///     * L2: Registers 23320, 23321
    ///     * L3: Registers 23322, 23323
    ///     * L1+L2+L3: Registers 23316, 23317
    func getElectricPower() async throws -> ElectricPower3PhaseGrid {
        let pL123 = try await self.modbusDevice.readHoldingRegisters(address: 23316, count: 2, unitId: self.unitId)
        let pL1 = try await self.modbusDevice.readHoldingRegisters(address: 23318, count: 2, unitId: self.unitId)
        let pL2 = try await self.modbusDevice.readHoldingRegisters(address: 23320, count: 2, unitId: self.unitId)
        let pL3 = try await self.modbusDevice.readHoldingRegisters(address: 23322, count: 2, unitId: self.unitId)

        guard let pL123Value = pL123.int32Value(at: 0),
              let pL1Value = pL1.int32Value(at: 0),
              let pL2Value = pL2.int32Value(at: 0),
              let pL3Value = pL3.int32Value(at: 0) else {
            throw SystemError.dataMissing
        }

        let currentPower = ElectricPower3PhaseGrid(
            powerL1: Measurement(value: Double(pL1Value)/100, unit: UnitPower.watts),
            powerL2: Measurement(value: Double(pL2Value)/100, unit: UnitPower.watts),
            powerL3: Measurement(value: Double(pL3Value)/100, unit: UnitPower.watts),
            powerTotal: Measurement(value: Double(pL123Value)/100, unit: UnitPower.watts)
        )
        return currentPower
    }

    /// Get Electric Energy (total)
    ///
    /// Return total energy provided by the EV charger (energy since installation).
    /// Refers to the total energy on all three phases!
    /// - Returns: Total energy provided by the EV charger since installation
    /// - Note: Refers to register address 20480 in corresponding modbus mapping.
    func getElectricEnergy() async throws -> Measurement<UnitEnergy> {
        let tEnergy = try await self.modbusDevice.readHoldingRegisters(address: 20480, count: 4, unitId: self.unitId)

        guard let tEnergyValue = tEnergy.uint64Value(at: 0, order: .abcd) else {
            throw SystemError.dataMissing
        }
        return Measurement(value: Double(tEnergyValue)/100, unit: UnitEnergy.kilowattHours)
    }
}
