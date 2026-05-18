//
//  ChargingSystem.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 20.04.26.
//

import Foundation


/// Charging Point
///
/// A charging point consists of a specific EV charger device and a specific power meter device.
/// It represents an abstraction layer for different physical chargers and power meters from different
/// vendors – allowing the app to interact with these chargers and power meters in a uniform, type-safe way.
///
/// This type composes a specific ``EVCharger`` together with a specific ``PowerMeter`` and implements
/// the following responsibilities:
/// - Initializing and wiring the selected charger and meter implementations
/// - Querying and updating charging and vehicle state
/// - Bridging vendor-specific capabilities behind a common interface
///
/// - Concurrency: ``ChargingPoint`` is an `actor`, which serializes access to its mutable state
///   and coordinates asynchronous interactions with the underlying RS485 bus layers (based on serial/UART).
///   Interact with it using `await` from concurrent contexts to ensure thread safety.
///
/// - Note: When using a charger with an integrated (non-MID) power meter, set ``powerMeterModel`` to
///   ``SupportedPowerMeter/nope`` to indicate that no separate MID-conforming meter is present.
actor ChargingPoint {

    /// Specific EV Charger
    ///
    /// The specific ev charger used for this charging system
    private let evCharger: EVCharger

    /// EV Charger Model
    ///
    /// Supported ev charger model as described in ``SupportedCharger``.
    var evChargerModel: SupportedCharger {
        self.evCharger.modelName
    }

    /// Specific Power Meter
    ///
    /// The specific power meter used for this charging system.
    private let powerMeter: PowerMeter

    /// Power Meter Model
    ///
    /// Supported power meter model as described in ``SupportedPowerMeter``.
    ///
    /// - Note: When the charger integrated power meter is in use, the model member equals `.nope`. This
    /// means that no MID conforming power meter is in use!
    var powerMeterModel: SupportedPowerMeter {
        self.powerMeter.modelName
    }

    /// Charging Point ID
    ///
    /// Canonical charging-point identifier used across app/backend and the physical site.
    /// Mirrors the charger's Modbus unit ID for simplicity reasons.
    ///
    /// - Note: The ``EVCharger`` unit ID is used here because a ``ChargingPoint`` can exist without
    /// a dedicated ``PowerMeter``. If no dedicated ``PowerMeter`` is used, only one bus exists.
    var cpId: UInt8 {
        return self.evCharger.unitId
    }

    /// Charging State
    ///
    /// Charger charging state: `.charging`, `.notCharging`, `.unknown` or `.error`
    var chargingState: ChargerState {
        get async throws {
            try await self.evCharger.getChargerState()
        }
    }

    /// EV State
    ///
    /// EV plugged state: `.pluggedIn`, `.unplugged`, `.unknown` or `.error`
    var evState: EVState {
        get async throws {
            try await self.evCharger.getEVPluggedState()
        }
    }

    /// Charging Permission
    ///
    /// Indicate if charging is `.enabled` or `.disabled` for this charger.
    ///
    /// - Note: In case it is disabled, no charging sessions can
    /// be initiated from the EV. The charger needs to be enabled (unlocked) at first.
    /// When a charging session gets disabled while in progress, the session is terminated gracefully.
    ///
    /// Refer to ``ChargingPoint/enableCharging()`` and ``ChargingPoint/disableCharging()``
    var chargingPermission: Status = .disabled


    /// Power Meter Reading
    ///
    /// Get actual power meter reading
    var meterReading: Measurement<UnitEnergy> {
        get async throws {
            let reading = try await self.powerMeter.getElectricEnergy()
            return reading
        }
    }

    /// Charging current
    ///
    /// Charging current as provided by power meter over three phases
    var chargingCurrent: ElectricCurrent3PhaseGrid {
        get async throws {
            let current = try await self.powerMeter.getElectricCurrent()
            return current
        }
    }

    /// Charging Power
    ///
    /// Return total charging power reported by power meter. The total power is
    /// provided by the power meter and represents the sum over the three phases.
    var chargingPower: ElectricPower3PhaseGrid {
        get async throws {
            let power = try await self.powerMeter.getElectricPower()
            return power
        }
    }

    /// Grid Voltage
    ///
    /// Return actual grid voltage
    var gridVoltage: ElectricVoltage3PhaseGrid {
        get async throws {
            let voltage = try await self.powerMeter.getGridVoltage()
            return voltage
        }
    }

    /// Logger
    ///
    /// The application-wide main logger
    private let logger = ComponentSupplier.mainLogger

    /// Init Charging System
    ///
    /// Ensure that charger and power meter share the same unit id.
    /// (This is possible as by design power meter and charger use two different RS485 bus transceivers!)
    init(evCharger: EVCharger, powerMeter: PowerMeter) async throws {
        self.evCharger = evCharger
        self.powerMeter = powerMeter

        try self.checkDeviceConsistency()
        try await self.evCharger.setupConfig()

        self.logger.info("""
                         Charging Point initialized with
                         - EV Charger: \(self.evCharger.modelName.rawValue) (Unit ID: \(self.evCharger.unitId))
                         - Power Meter: \(self.powerMeter.modelName.rawValue) (Unit ID: \(self.powerMeter.unitId))
                        """)
    }

    // MARK: - Charger Functions

    /// Enable Charging
    ///
    /// Unlock the charger and enable charging
    func enableCharging() async throws -> Status {
        let lockState = try await self.evCharger.setSoftwareLock(to: .unlocked)
        self.chargingPermission = lockState.asStatus
        return self.chargingPermission
    }

    /// Disable Charging
    ///
    /// Lock the charger and disable charging.
    /// Any running charging session will be terminated gracefully.
    func disableCharging() async throws -> Status {
        let lockState = try await self.evCharger.setSoftwareLock(to: .locked)
        self.chargingPermission = lockState.asStatus
        return self.chargingPermission
    }

    /// Set Charging Current Limitter Setpoint
    ///
    /// The charging current is mainly controlled by the EV but the charger can limit the charging current.
    /// This function is limitting the charging current to the defined maximum.
    ///
    /// - Parameter current: Limit charging to the given maximum current
    /// - Returns: Charging current setpoint accepted by device
    func setChargingCurrent(to current: Measurement<UnitElectricCurrent>) async throws -> Measurement<UnitElectricCurrent> {
        let chargerHardwareCurrentLimits = try await evCharger.getFixedCurrentLimits()
        let currentLimit = max(min(current, chargerHardwareCurrentLimits.maximal), chargerHardwareCurrentLimits.minimal)
        let currentLimitAcknowleged = try await evCharger.setCurrentLimit(to: currentLimit)
        return currentLimitAcknowleged
    }

    // MARK: - Private Helper Functions


    /// Check Device Consistency
    ///
    /// Ensure that charger and power meter share the same unit id.
    /// (This is possible as by design power meter and charger use two different RS485 bus transceivers!)
    ///
    /// Ensure that charger and power meter are not set to `.unknown`. This indicates an unsupported device.
    ///
    /// - Throws: ``SystemError/unitIdMissmatch``
    private func checkDeviceConsistency() throws {
        if self.evCharger.unitId != self.powerMeter.unitId {
            let err = SystemError.unitIdMissmatch
            self.logger.critical("\(err.localizedDescription ?? String(describing: err))")
            throw err
        }

        if self.evCharger.modelName == .unknown || self.powerMeter.modelName == .unknown {
            let err = SystemError.unsupportedDevice
            self.logger.critical("\(err.localizedDescription ?? String(describing: err))")
            throw err
        }
    }

}
