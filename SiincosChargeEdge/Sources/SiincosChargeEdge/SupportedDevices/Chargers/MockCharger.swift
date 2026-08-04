//
//  MockCharger.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 17.04.26.
//

import Foundation
import ModbusSerial


struct MockCharger: EVCharger {
    let unitId: UInt8
    let modelName: SupportedCharger
    let evState: EVState = { Bool.random() ? .pluggedIn : .unplugged }()
    let chargerDataStore: MockChargerDataStore = MockChargerDataStore()

    func setupConfig() async throws {
        print("MockCharger: Config Setup completed!")
    }
    
    func getChargerState() async throws -> ChargerState {
        var chargingState: ChargerState = .notCharging
        if self.evState == .pluggedIn {
            chargingState = await chargerDataStore.softwareLockState == .locked ? ChargerState.notCharging : ChargerState.charging
        }
        //print("Current charging state: \(chargingState)")
        return chargingState
    }

    func getEVPluggedState() async throws -> EVState {
        //print("EV is currently: \(self.evState)")
        return self.evState
    }

    func getInternalTemperature() async throws -> Measurement<UnitTemperature> {
        let internalTemperature = Measurement(value: 32.4, unit: UnitTemperature.celsius)
        //print("Internal Temperature: \(internalTemperature)")
        return internalTemperature
    }
    
    func getFixedCurrentLimits() async throws -> Boundaries<Measurement<UnitElectricCurrent>> {
        let boundaries = try Boundaries(
            minimal: Measurement(value: 6.0, unit: UnitElectricCurrent.amperes),
            maximal: Measurement(value: 16.0, unit: UnitElectricCurrent.amperes))
        //print("Hardware electric current limits: \(boundaries)")
        return boundaries
    }
    
    func getCurrentLimit() async throws -> Measurement<UnitElectricCurrent> {
        //print("Currently set max. current: \(await self.chargerDataStore.maxCurrentLimit)")
        return await self.chargerDataStore.maxCurrentLimit
    }

    /// Set maximum current limit
    ///
    /// ``MockCharger`` has to make sure that current limit setpoint stays within the predefined bounds (6A...16A)
    func setCurrentLimit(to setpoint: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent> {
        if setpoint.value >= 16.0 {
            await self.chargerDataStore.setMaxCurrentLimit(Measurement(value: 16.0, unit: .amperes))
        } else if setpoint.value <= 6.0 {
            await self.chargerDataStore.setMaxCurrentLimit(Measurement(value: 6.0, unit: .amperes))
        } else {
            var setpointFloored = setpoint
            setpointFloored.value = floor(setpoint.value)
            await self.chargerDataStore.setMaxCurrentLimit(setpointFloored)
        }
        //await print("Setting max. current to: \(self.chargerDataStore.maxCurrentLimit)")
        return try await self.getCurrentLimit()
    }
    
    func getHardwareLockState() async throws -> LockState {
        let hardwareLockState: LockState = .unlocked
        //print("Hardware Lock State: \(hardwareLockState)")
        return hardwareLockState
    }
    
    func getSoftwareLockState() async throws -> LockState {
        //await print("Current lock state: \(self.chargerDataStore.softwareLockState)")
        return await self.chargerDataStore.softwareLockState
    }
    
    func setSoftwareLock(to: LockState) async throws -> LockState {
        await self.chargerDataStore.setSoftwareLockState(to: to)
        //await print("Setting lock state to: \(self.chargerDataStore.softwareLockState)")
        return await self.chargerDataStore.softwareLockState
    }
}


struct MockChargerPowerMeter: PowerMeter {
    let unitId: UInt8
    let modelName: SupportedPowerMeter
    let chargerDataStore: MockChargerDataStore = MockChargerDataStore()

    func getElectricCurrent() async throws -> ElectricCurrent3PhaseGrid {
        let current = ElectricCurrent3PhaseGrid(
            currentL1: Measurement(value: 7.3, unit: UnitElectricCurrent.amperes),
            currentL2: Measurement(value: 8.1, unit: UnitElectricCurrent.amperes),
            currentL3: Measurement(value: 6.9, unit: UnitElectricCurrent.amperes)
        )
        //print("Current: \(current)")
        return current
    }
    
    func getGridVoltage() async throws -> ElectricVoltage3PhaseGrid {
        let voltage = ElectricVoltage3PhaseGrid(
            voltageL1: Measurement(value: 228.8, unit: UnitElectricPotentialDifference.volts),
            voltageL2: Measurement(value: 236.4, unit: UnitElectricPotentialDifference.volts),
            voltageL3: Measurement(value: 231.1, unit: UnitElectricPotentialDifference.volts)
            )
        //print("Voltage: \(voltage)")
        return voltage
    }
    
    func getElectricPower() async throws -> ElectricPower3PhaseGrid {
        let power = ElectricPower3PhaseGrid(
            powerL1: Measurement(value: 5200.0, unit: UnitPower.watts),
            powerL2: Measurement(value: 4800.0, unit: UnitPower.watts),
            powerL3: Measurement(value: 5300.0, unit: UnitPower.watts),
            powerTotal: Measurement(value: 15300.0, unit: UnitPower.watts)
        )
        //print("Power: \(power)")
        return power
    }
    
    func getElectricEnergy() async throws -> Measurement<UnitEnergy> {
        let newEnergy = await self.chargerDataStore.energy.value + 0.5
        await self.chargerDataStore.setEnergy(Measurement(value: newEnergy, unit: UnitEnergy.kilowattHours))
        //await print("Energy drawn since installation: \(self.chargerDataStore.energy)")
        return await self.chargerDataStore.energy
    }
}



actor MockChargerDataStore: Sendable {
    var maxCurrentLimit = Measurement(value: 16.0, unit: UnitElectricCurrent.amperes)
    var softwareLockState: LockState = .locked
    var energy = Measurement(value: 1.0, unit: UnitEnergy.kilowattHours)

    /// Set maximum current limit Setpoint
    func setMaxCurrentLimit(_ limit: Measurement<UnitElectricCurrent>) {
        self.maxCurrentLimit = limit
    }

    /// Set software lock-state
    func setSoftwareLockState(to: LockState) {
        self.softwareLockState = to
    }

    /// Set energy
    func setEnergy(_ energy: Measurement<UnitEnergy>) {
        self.energy = energy
    }
}

