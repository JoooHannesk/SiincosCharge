//
//  ChargingSystem.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 20.04.26.
//

import Foundation


/// Charging System
///
/// A charging system consists of a specific EV charger device and a specific power meter device.
/// It represents an abstraction layer for different physical chargers and power meters from different
/// vendors – allowing the app to interact with these chargers and power meters in a uniform, type-safe way.
///
/// This type composes a specific ``EVCharger`` together with a specific ``PowerMeter`` and implements
/// the following responsibilities:
/// - Initializing and wiring the selected charger and meter implementations
/// - Querying and updating charging and vehicle state
/// - Bridging vendor-specific capabilities behind a common interface
///
/// - Concurrency: ``ChargingSystem`` is an `actor`, which serializes access to its mutable state
///   and coordinates asynchronous interactions with the underlying RS485 bus layers (based on serial/UART).
///   Interact with it using `await` from concurrent contexts to ensure thread safety.
///
/// - Note: When using a charger with an integrated (non-MID) power meter, set ``powerMeterModel`` to
///   ``SupportedPowerMeter/nope`` to indicate that no separate MID-conforming meter is present.
actor ChargingSystem {

    /// Specific EV Charger
    ///
    /// The specific ev charger used for this charging system
    private let evCharger: EVCharger

    /// EV Charger Model
    ///
    /// Supported ev charger model as described in ``SupportedCharger``.
    var evChargerModel: SupportedCharger

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
    var powerMeterModel: SupportedPowerMeter

    /// Charging State
    ///
    /// Charger charging state: `.charging`, `.notCharging`, `.unknown` or `.error`
    var chargingState: ChargerState = .unknown

    /// EV State
    ///
    /// EV plugged state: `.pluggedIn`, `.unplugged`, `.unknown` or `.error`
    var evState: EVState = .unknown

    /// Charging Permission
    ///
    /// Indicate if charging is `.enabled` or `.disabled` for this charger.
    ///
    /// - Note: In case it is disabled, no charging sessions can
    /// be initiated from the EV. The charger needs to be enabled (unlocked) at first.
    /// When a charging session gets disabled while in progress, the session is terminated gracefully.
    ///
    /// Refer to ``ChargingSystem/enableCharging()`` and ``ChargingSystem/disableCharging()``
    var chargingPermission: Status = .disabled

    init(evCharger: EVCharger, evChargerModel: SupportedCharger, powerMeter: PowerMeter, powerMeterModel: SupportedPowerMeter) {
        self.evCharger = evCharger
        self.evChargerModel = evChargerModel
        self.powerMeter = powerMeter
        self.powerMeterModel = powerMeterModel

        // self.evCharger.setupConfig() // TODO: try to call somewhere in this context
    }

    // MARK: - Public Charger Functions

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

    /// Set Charging Current Setpoint
    ///
    /// The charging current is mainly controlled by the EV but the charger can limit the charging current.
    /// This function is limitting the charging current to the defined maximum.
    ///
    /// - Parameter amperes: Limit charging to the given maximum current
    /// - Returns: Charging current setpoint accepted by device
    func setChargingCurrent(to amperes: Double) async throws -> Double {
        let chargerHardwareCurrentLimits = try await evCharger.getHardwareCurrentLimits()
        let setpoint = Measurement(value: amperes, unit: UnitElectricCurrent.amperes)
        let currentLimit = max(min(setpoint, chargerHardwareCurrentLimits.maximal), chargerHardwareCurrentLimits.minimal)
        let currentLimitAcknowleged = try await evCharger.setMaxCurrentLimitSetpoint(to: currentLimit)
        return currentLimitAcknowleged.value
    }
}
