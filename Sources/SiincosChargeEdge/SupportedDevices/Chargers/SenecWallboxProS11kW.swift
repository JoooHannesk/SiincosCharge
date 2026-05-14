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
/// Senec Wallbox Pro S as Modbus Device
struct SenecWallboxProS11kW: EVCharger, ModbusRTUDevice {

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
    let modelName: SupportedCharger

    /// Initializer
    ///
    /// Instance requires a modbus client configuration, the specific unit id on the bus system
    /// and the specific device model name
    ///
    /// - Parameters:
    ///    - modbusRTUClient: Configured modbus client, connected
    ///    - unitId: Device unit id on the modbus bus
    ///    - modelName: Specific device model name for better identification
    init(modbusRTUClient: ModbusRTUClient, unitId: UInt8, modelName: String) {
        self.modbusDevice = modbusRTUClient
        self.unitId = unitId
        self.modelName = SupportedCharger.init(rawValue: modelName) ?? .unknown
    }

    /// Setup Configuration
    ///
    /// Setup device by loading device specific default configuration which
    /// is required for proper operation.
    /// Setting the following device specific parameters:
    /// - Power Saving Mode: Enable power saving mode when idle (no car connected)
    /// - Watchdog Timeout: 60 seconds (prevent watchdog to trigger failsafe mode too early, e.g. the gateway power-cycles should not trigger the watchdog)
    /// - Failsafe Mode max. Current: 8A (for most cases assuming at most 2 chargers on the line – with 8 amps each, the circuit breaker will not trip)
    func setupConfig() async throws {
        // Power Saving Mode: enabled
        let powerSavingModeSetpoint: Status = .enabled
        let powerSavingModeActual = try await self.setPowerSavingState(to: powerSavingModeSetpoint)

        // Watchdog Timeout: 60sec
        let watchDogTimeOutSetpoint: UInt16 = 60000
        let watchdogTimeoutActual = try await self.setModbusWatchdogTimeout(to: watchDogTimeOutSetpoint)

        // Failsafe Mode: 8A max. current
        let failsafeCurrentSetpoint = Measurement(value: Double(8.0), unit: UnitElectricCurrent.amperes)
        let failsafeCurrentActual = try await self.setCommFailureMaxCurrent(to: failsafeCurrentSetpoint)

        guard powerSavingModeActual == powerSavingModeSetpoint, watchdogTimeoutActual == watchDogTimeOutSetpoint, failsafeCurrentActual == failsafeCurrentSetpoint else {
            throw SystemError.deviceConfigurationError
        }
    }


    /// Get specific Charger State
    ///
    /// Retrieve device specific charger state
    /// - Returns: ``SenecWallboxProSChargerState``
    /// - Note: Refers to register address 5 in corresponding modbus mapping
    private func getSpecificChargerState() async throws -> SenecWallboxProSChargerState {
        let response = try await self.modbusDevice.readInputRegisters(address: 5, count: 1, unitId: self.unitId)
        guard let state = response.value(at: 0) else {
            throw SystemError.dataMissing
        }
        let specificChargerState = SenecWallboxProSChargerState.getSpecificChargerStateForModbusValue(state)
        return specificChargerState
    }

    /// Get Charging State
    ///
    /// Retrieve the charger state from device and translate it to
    /// harmonized charging state
    ///
    /// - Returns: ``ChargerState``
    /// - Note: Refers to register address 5 in corresponding modbus mapping
    func getChargerState() async throws -> ChargerState {
        let specificChargerState = try await self.getSpecificChargerState()
        let harmonizedChargerState = SenecWallboxProSChargerState.getHarmonizedChargerStateForSpecificChargerState(specificChargerState)
        Self.logger.info("Translating specific charger state \(specificChargerState) to harmonized charger state \(harmonizedChargerState)")
        return harmonizedChargerState
    }

    /// Get EV Plugged State
    ///
    /// Retrieve the EV plugged state from device and translate it to
    /// harmonized states
    ///
    /// - Returns: ``EVState``
    /// - Note: Refers to register address 5 in corresponding modbus mapping
    func getEVPluggedState() async throws -> EVState {
        let specificChargerState = try await self.getSpecificChargerState()
        let harmonizedPluggedStates = SenecWallboxProSChargerState.getHarmonizedEVPluggedStateForSpecificChargerState(specificChargerState)
        Self.logger.info("Translating specific charger plugged state \(specificChargerState) to harmonized plugged state \(harmonizedPluggedStates)")
        return harmonizedPluggedStates
    }

    /// Get Internal Temperature
    ///
    /// Retrieve internal system temperature from charger. Required for monitoring and system health diagnosis.
    ///
    /// - Returns: internal system temperature
    /// - Note: Refers to register address 9 in corresponding modbus mapping
    func getInternalTemperature() async throws -> Measurement<UnitTemperature> {
        let response = try await self.modbusDevice.readInputRegisters(address: 9, count: 1, unitId: self.unitId)
        guard let temperatureValue = response.signedValue(at: 0) else {
            throw SystemError.dataMissing
        }
        let temperature = Double(temperatureValue)/10.0
        return Measurement(value: temperature, unit: UnitTemperature.celsius)
    }

    /// Get Hardware Current Limits
    ///
    /// The charger is bound to specific electric current limits, given by the overall hardware design and the installation limits.
    /// These limits are required to ensure proper system functionality such as load balancing, equal current distribution, etc.
    ///
    /// - Returns: Current limites (given by hardware and/or installation)
    /// - Note: Refers to register addresses 100 and 101 in corresponding modbus mapping
    func getHardwareCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>> {
        let responseMinimalCurrent = try await self.modbusDevice.readInputRegisters(address: 101, count: 1, unitId: self.unitId)
        let responseMaximalCurrent = try await self.modbusDevice.readInputRegisters(address: 100, count: 1, unitId: self.unitId)
        guard let minimalCurrentValue = responseMinimalCurrent.value(at: 0), let maximalCurrentValue = responseMaximalCurrent.value(at: 0)  else {
            throw SystemError.dataMissing
        }
        return try Boundaries(minimal: Measurement(value: Double(minimalCurrentValue), unit: UnitElectricCurrent.amperes),
                              maximal: Measurement(value: Double(maximalCurrentValue), unit: UnitElectricCurrent.amperes))
    }

    /// Get Max Current Limit Setpoint
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle. This function retrieves the
    /// current setpoint from the charger and returns it.
    ///
    /// - Returns: acutal electrical current setpoint
    /// - Note: Refers to register address 261 in corresponding modbus mapping. This value is not retained in the charger and
    /// will not survive a power cylce!
    func getMaxCurrentLimitSetpoint() async throws -> Measurement<UnitElectricCurrent> {
        let responseCurrentSetpoint = try await self.modbusDevice.readHoldingRegisters(address: 261, count: 1, unitId: self.unitId)
        guard var responseCurrentSetpointValue = responseCurrentSetpoint.value(at: 0) else {
            throw SystemError.dataMissing
        }
        responseCurrentSetpointValue /= 10 // Required per modbus documentation
        return Measurement(value: Double(responseCurrentSetpointValue), unit: UnitElectricCurrent.amperes)
    }

    /// Set Max Current Limit Setpoint
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle. This function sets the
    /// maximum current setpoint in the charger.
    ///
    /// - Parameter setpoint: Current limit setpoint to transfer to the charger
    /// - Returns: Acutal electrical current setpoint, processed by the charger.
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
        guard let lockStateValue = lockState.value(at: 0) else {
            throw SystemError.dataMissing
        }
        return LockState(rawValue: UInt(lockStateValue)) ?? .unknown
    }

    /// Get Software Lock State
    ///
    /// Chargers need to have a software lock which is required to be unlocked before a charging session can be started. This
    /// function returns the actual lock state. Refer to ``SenecWallboxProS11kW/setSoftwareLock(to:)`` for unlocking the
    /// software lock.
    ///
    /// - Returns: lock state as type ``SiincosChargeEdge/LockState``
    /// - Note: Refers to register address 259 in corresponding modbus mapping.
    func getSoftwareLockState() async throws -> LockState {
        let lockState = try await self.modbusDevice.readHoldingRegisters(address: 259, count: 1, unitId: self.unitId)
        guard let lockStateValue = lockState.value(at: 0) else {
            throw SystemError.dataMissing
        }
        return LockState(rawValue: UInt(lockStateValue)) ?? .unknown
    }

    /// Set Software Lock State
    ///
    /// Chargers need to have a software lock which is required to be unlocked before a charging session can be started. This
    /// function locks or unlocks the software lock.
    ///
    /// - Parameter state: Lock state to set
    /// - Returns: lock state as type ``LockState``, processed by the charger
    /// - Note: Refers to register address 259 in corresponding modbus mapping.
    func setSoftwareLock(to state: LockState) async throws -> LockState {
        let lockState = UInt16(state.rawValue)
        let _ = try await self.modbusDevice.writeMultipleRegisters(address: 259, values: [lockState], unitId: self.unitId)
        let newStateProcessByCharger = try await self.getSoftwareLockState()
        return newStateProcessByCharger
    }

    // MARK: Device specific functionality

    /// Get device power saving state
    ///
    /// The charger will only enter powersaving mode (if enabled) in case no EV is plugged in.
    ///
    /// - Returns: Power saving status as ``Status``
    /// - Note: Referred to as *Standby Mode* in modbus mapping manual (register address 258)
    func getPowerSavingState() async throws -> Status {
        let status = try await self.modbusDevice.readHoldingRegisters(address: 258, count: 1, unitId: self.unitId)
        guard let statusValue = status.value(at: 0) else {
            throw SystemError.dataMissing
        }
        switch statusValue {
        case 0:
            return .enabled
        case 4:
            return .disabled
        default:
            return .unknown
        }
    }

    /// Set device power saving state
    ///
    /// Providing any other argument instead of `.enabled` or `.disabled` results in
    /// power saving mode being disabled.
    ///
    /// The charger will only enter powersaving mode (if enabled) in case no EV is plugged in.
    ///
    /// - Parameter to: Power saving status as ``Status``
    /// - Note: Referred to as *Standby Mode* in modbus mapping manual (register address 258)
    func setPowerSavingState(to: Status) async throws -> Status {
        let powerSavingState: UInt16
        if to == .enabled {
            powerSavingState = 0
        } else {
            powerSavingState = 4
        }
        let _ = try await self.modbusDevice.writeMultipleRegisters(address: 258, values: [powerSavingState], unitId: self.unitId)
        let newPowerSavingState = try await self.getPowerSavingState()
        return newPowerSavingState
    }

    /// Get Modbus Watchdog Timeout
    ///
    /// In case of a communication failure on the modbus line, the charger goes into failsafe mode
    /// after the defined timeout. The failsafe mode reduces to charging current to the configured failsafe-maximum
    /// and indicates an error through its LED display.
    ///
    /// - Returns: Timeout in milliseconds as `UInt16`. Max value: 65535
    /// - Note: Refers to register address 257 in corresponding modbus mapping.
    func getModbusWatchdogTimeout() async throws -> UInt16 {
        let wdTimeout = try await self.modbusDevice.readHoldingRegisters(address: 257, count: 1, unitId: self.unitId)
        guard let wdTimeoutValue = wdTimeout.value(at: 0) else {
            throw SystemError.dataMissing
        }
        return UInt16(wdTimeoutValue)
    }

    /// Set Modbus Watchdog Timeout
    ///
    /// In case of a communication failure on the modbus line, the charger goes into failsafe mode
    /// after the defined timeout. The failsafe mode reduces to charging current to the configured failsafe-maximum
    /// and indicates an error through its LED display.
    ///
    /// - Parameter milliseconds: Timeout in milliseconds as `UInt16`. Max value: 65535
    /// - Note: Refers to register address 257 in corresponding modbus mapping.
    func setModbusWatchdogTimeout(to milliseconds: UInt16) async throws -> UInt16 {
        let _ = try await self.modbusDevice.writeMultipleRegisters(address: 257, values: [milliseconds], unitId: self.unitId)
        let newWdTimeout = try await self.getModbusWatchdogTimeout()
        return newWdTimeout
    }

    /// Get Modbus Communication Failure Current Limit
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle in
    /// case the modbus communication breaks. This function reads the fallback current limit for the case.
    ///
    /// - Returns: Fallback electrical current setpoint
    /// - Note: Refers to register address 262 in corresponding modbus mapping. This value is not retained in the charger and
    /// will not survive a power cylce!
    func getCommFailureMaxCurrent() async throws -> Measurement<UnitElectricCurrent> {
        let responseCurrentSetpoint = try await self.modbusDevice.readHoldingRegisters(address: 262, count: 1, unitId: self.unitId)
        guard var responseCurrentSetpointValue = responseCurrentSetpoint.value(at: 0) else {
            throw SystemError.dataMissing
        }
        // Divison by 10 per modbus documentation
        responseCurrentSetpointValue /= 10
        return Measurement(value: Double(responseCurrentSetpointValue), unit: UnitElectricCurrent.amperes)
    }

    /// Set Modbus Communication Failure Current Limit
    ///
    /// The charger can dynamically adapt the maximum electrical current drawn from the grid and delivered to the vehicle in
    /// case the modbus communication breaks. This function sets the maximum current limit for this case.
    ///
    /// - Parameter setpoint: Current limit setpoint to transfer to the charger
    /// - Returns: Fallback electrical current setpoint, processed by the charger.
    /// - Note: In case the provided current setpoint exceeds the maximum hardware current limit, the hardware specific limit is transferred to the charger. Refers
    /// to register address 262 in corresponding modbus mapping.
    func setCommFailureMaxCurrent(to setpoint: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent> {
        let hardwareLimits = try await self.getHardwareCurrentLimits()
        // ensure to not exceed the hardware current constraints
        let newSetpoint = max(min(setpoint, hardwareLimits.maximal), hardwareLimits.minimal)
        // Multiplication with 10 required per modbus documentation
        let newSetpointInt = UInt16(newSetpoint.value * 10)
        let _ = try await self.modbusDevice.writeMultipleRegisters(address: 262, values: [newSetpointInt], unitId: self.unitId)
        let newSetpointProcessedByCharger = try await self.getCommFailureMaxCurrent()
        return newSetpointProcessedByCharger
    }

}

/// Power Meter inside Senec Wallbox Pro S
///
/// Senec Wallbox Pro S has an integrated power meter.
/// - Note: Power meter and charger are separated because the system architecutre allows to
/// use an external, dedicated power meter instead of the integrated one
///
struct SenecWallboxProSPowerMeter: PowerMeter, ModbusRTUDevice {
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
    init(modbusRTUClient: ModbusRTUClient, unitId: UInt8, modelName: String) {
        self.modbusDevice = modbusRTUClient
        self.unitId = unitId
        self.modelName = SupportedPowerMeter.init(rawValue: modelName) ?? .unknown
    }

    /// Get Electric Current
    ///
    /// Return electric current drawn by the EV.
    /// - Returns: Electric current drawn by the EV on a 3-phase grid
    /// - Note: Refers to the following register addresses in corresponding modbus mapping:
    ///     * L1: Register 6
    ///     * L2: Register 7
    ///     * L3: Register 8
    func getElectricCurrent() async throws -> ElectricCurrent3PhaseGrid {
        let il1 = try await self.modbusDevice.readInputRegisters(address: 6, count: 1, unitId: self.unitId)
        let il2 = try await self.modbusDevice.readInputRegisters(address: 7, count: 1, unitId: self.unitId)
        let il3 = try await self.modbusDevice.readInputRegisters(address: 8, count: 1, unitId: self.unitId)

        guard let il1Value = il1.value(at: 0), let il2Value = il2.value(at: 0), let il3Value = il3.value(at: 0) else {
            throw SystemError.dataMissing
        }
        let currentDrawn = ElectricCurrent3PhaseGrid(
            currentL1: Measurement(value: Double(il1Value)/10, unit: UnitElectricCurrent.amperes),
            currentL2: Measurement(value: Double(il2Value)/10, unit: UnitElectricCurrent.amperes),
            currentL3: Measurement(value: Double(il3Value)/10, unit: UnitElectricCurrent.amperes)
        )
        return currentDrawn
    }

    /// Get Electric Grid Voltage
    ///
    /// Return electric voltage provided by the power grid.
    /// - Returns: Electric voltage for a 3-phase grid
    /// - Note: Refers to the following register addresses in the corresponding modbus mapping:
    ///     * L1: Register 10
    ///     * L2: Register 11
    ///     * L3: Register 12
    func getGridVoltage() async throws -> ElectricVoltage3PhaseGrid {
        let ul1 = try await self.modbusDevice.readInputRegisters(address: 10, count: 1, unitId: self.unitId)
        let ul2 = try await self.modbusDevice.readInputRegisters(address: 11, count: 1, unitId: self.unitId)
        let ul3 = try await self.modbusDevice.readInputRegisters(address: 12, count: 1, unitId: self.unitId)

        guard let ul1Value = ul1.value(at: 0), let ul2Value = ul2.value(at: 0), let ul3Value = ul3.value(at: 0) else {
            throw SystemError.dataMissing
        }
        let gridVoltage3phase = ElectricVoltage3PhaseGrid(
            voltageL1: Measurement(value: Double(ul1Value), unit: UnitElectricPotentialDifference.volts),
            voltageL2: Measurement(value: Double(ul2Value), unit: UnitElectricPotentialDifference.volts),
            voltageL3: Measurement(value: Double(ul3Value), unit: UnitElectricPotentialDifference.volts)
        )
        return gridVoltage3phase
    }

    /// Get Electric Power
    ///
    /// Get electric power drawn from EV charger and delivered by grid: Active Power
    /// This power meter provides the total power (L1+L2+L3) only, therefore requesting `powerTotal` from
    /// the power meter and calculating L1, L2, L3 power based on current and grid voltage.
    ///
    /// - Returns: Electric power currently drawn by the EV (power for a 3-phase grid).
    ///
    /// - Note: The total power `powerTotal` refers to register 14 in modbus mapping. Voltage and Current
    /// is provided by ``getGridVoltage()`` and ``getElectricCurrent()``.
    ///
    func getElectricPower() async throws -> ElectricPower3PhaseGrid {
        let voltage = try await self.getGridVoltage()
        let current = try await self.getElectricCurrent()
        let pl123 = try await self.modbusDevice.readInputRegisters(address: 14, count: 1, unitId: self.unitId)

        guard let pl123Value = pl123.value(at: 0) else {
            throw SystemError.dataMissing
        }

        let powerL1 = (voltage.voltageL1?.value ?? 0.0) * (current.currentL1?.value ?? 0.0)
        let powerL2 = (voltage.voltageL2?.value ?? 0.0) * (current.currentL2?.value ?? 0.0)
        let powerL3 = (voltage.voltageL3?.value ?? 0.0) * (current.currentL3?.value ?? 0.0)

        let currentPower = ElectricPower3PhaseGrid(
            powerL1: Measurement(value: powerL1, unit: UnitPower.watts),
            powerL2: Measurement(value: powerL2, unit: UnitPower.watts),
            powerL3: Measurement(value: powerL3, unit: UnitPower.watts),
            powerTotal: Measurement(value: Double(pl123Value), unit: UnitPower.watts)
        )
        return currentPower
    }

    /// Get Electric Energy (total)
    ///
    /// Return total energy provided by the EV charger (energy since installation).
    /// - Returns: Total energy provided by the EV charger since installation
    /// - Note: Refers to register address 17 and 18 in corresponding modbus mapping.
    func getElectricEnergy() async throws -> Measurement<UnitEnergy> {
        let tEnergyHighByte = try await self.modbusDevice.readInputRegisters(address: 17, count: 1, unitId: self.unitId)
        let tEnergyLowByte = try await self.modbusDevice.readInputRegisters(address: 18, count: 1, unitId: self.unitId)

        guard let tEnergyHighByteValue = tEnergyHighByte.value(at: 0), let tEnergyLowByteValue = tEnergyLowByte.value(at: 0) else {
            throw SystemError.dataMissing
        }

        // This does the following: << 16 shifts high bytes to the left by a full 16-bit register, | adds the lower bytes
        // Math behind this: totalEnergy = (high * 65536) + low --> high << 16: multiply by 65536, | low: add the lower bits
        let totalEnergyVAhSinceInstallation = UInt32(tEnergyHighByteValue) << 16 | UInt32(tEnergyLowByteValue)
        return Measurement(value: Double(totalEnergyVAhSinceInstallation)/1000, unit: UnitEnergy.kilowattHours)
    }

    // MARK: Device specific functionality

    /// Get Electric Energy (since power on)
    ///
    /// Return total energy provided by the EV charger (energy since power on).
    /// - Returns: Total energy provided by the EV charger since power on
    /// - Note: Refers to register address 15 and 16 in corresponding modbus mapping.
    func getElectricEnergySincePowerOn() async throws -> Measurement<UnitEnergy> {
        let spoEnergyHighByte = try await self.modbusDevice.readInputRegisters(address: 15, count: 1, unitId: self.unitId)
        let spoEnergyLowByte = try await self.modbusDevice.readInputRegisters(address: 16, count: 1, unitId: self.unitId)

        guard let spoEnergyHighByteValue = spoEnergyHighByte.value(at: 0), let spoEnergyLowByteValue = spoEnergyLowByte.value(at: 0) else {
            throw SystemError.dataMissing
        }

        // This does the following: << 16 shifts high bytes to the left by a full 16-bit register, | adds the lower bytes
        // Math behind this: totalEnergy = (high * 65536) + low --> high << 16: multiply by 65536, | low: add the lower bits
        let totalEnergyVAhSincePowerOn = UInt32(spoEnergyHighByteValue) << 16 | UInt32(spoEnergyLowByteValue)
        return Measurement(value: Double(totalEnergyVAhSincePowerOn)/1000, unit: UnitEnergy.kilowattHours)
    }
}

/// Senec Wallbox Pro S Specific Car Charger States
///
enum SenecWallboxProSChargerState {

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
    case chargingDerated // TODO: check status name and description
    case e // TODO: check status name and description
    case f // TODO: check status name and description
    case chargingError

    /// Get charger specific state
    ///
    /// Get specific charger state based on integer value provided through modbus rtu register
    /// - Parameter value: Integer value retrieved from device via Modbus
    /// - Returns: Specific charger state as ``SenecWallboxProSChargerState``
    static func getSpecificChargerStateForModbusValue(_ value: UInt16) -> SenecWallboxProSChargerState {
        let specificChargerState: SenecWallboxProSChargerState
        switch value {
        case 2:
            specificChargerState = .vehicleNotPresentChargerNotReady
        case 3:
            specificChargerState = .vehicleNotPresentChargerReady
        case 4:
            specificChargerState = .vehiclePresentNoRequestChargerNotReady
        case 5:
            specificChargerState = .vehiclePresentNoRequestChargerReady
        case 6:
            specificChargerState = .vehiclePresentRequestChargerNotReady
        case 7:
            specificChargerState = .vehiclePresentRequestChargerReady
        case 8:
            specificChargerState = .chargingDerated
        case 9:
            specificChargerState = .e
        case 10:
            specificChargerState = .f
        case 11:
            specificChargerState = .chargingError
        default:
            specificChargerState = .unknown
        }
        return specificChargerState
    }

    /// Get Harmonized Charger State
    ///
    /// Get harmonized charger state based on the specific charger state.
    /// It is required to treat multiple different charger models technically equal.
    static func getHarmonizedChargerStateForSpecificChargerState(_ specificChargerState: SenecWallboxProSChargerState) -> ChargerState {
        let harmonizedChargerState: ChargerState

        switch specificChargerState {
        case unknown: harmonizedChargerState = .unknown
        // vehicle not present
        case vehicleNotPresentChargerReady: harmonizedChargerState = .notCharging
        case vehicleNotPresentChargerNotReady: harmonizedChargerState = .notCharging
        // vehicle present no charging request
        case vehiclePresentNoRequestChargerReady: harmonizedChargerState = .notCharging
        case vehiclePresentNoRequestChargerNotReady: harmonizedChargerState = .notCharging
        // vehicle present charging request
        case vehiclePresentRequestChargerReady: harmonizedChargerState = .charging
        case vehiclePresentRequestChargerNotReady: harmonizedChargerState = .notCharging
        // other states
        case chargingDerated: harmonizedChargerState = .charging
        case e: harmonizedChargerState = .unknown
        case f: harmonizedChargerState = .unknown
        case chargingError: harmonizedChargerState = .error
        }

        return harmonizedChargerState
    }

    /// Get harmonized EV Plugged State
    ///
    /// Get harmonized EV plugged state based on the specific charger state.
    /// It is required to treat multiple different charger models technically equal.
    static func getHarmonizedEVPluggedStateForSpecificChargerState(_ specificChargerState: SenecWallboxProSChargerState) -> EVState {
        let evPluggedState: EVState

        switch specificChargerState {
        case unknown: evPluggedState = .unknown
        // vehicle not present
        case vehicleNotPresentChargerReady: evPluggedState = .unplugged
        case vehicleNotPresentChargerNotReady: evPluggedState = .unplugged
        // vehicle present no charging request
        case vehiclePresentNoRequestChargerReady: evPluggedState = .pluggedIn
        case vehiclePresentNoRequestChargerNotReady: evPluggedState = .pluggedIn
        // vehicle present charging request
        case vehiclePresentRequestChargerReady: evPluggedState = .pluggedIn
        case vehiclePresentRequestChargerNotReady: evPluggedState = .pluggedIn
        // other states
        case chargingDerated: evPluggedState = .pluggedIn
        case e: evPluggedState = .unknown
        case f: evPluggedState = .unknown
        case chargingError: evPluggedState = .error
        }
        return evPluggedState
    }
}
