//
//  SiincosChargingSystem.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 20.04.26.
//


/// Charging System
///
/// A charging system consists of a specific EV charger device and a specific power meter.
/// It represents an abstraction layer for different physical chargers and power meters from different
/// vendors – allowing 
actor ChargingSystem {

    /// Specific EV Charger
    ///
    /// The specific ev charger used for this charging system
    let evCharger: EVCharger

    /// EV Charger Model
    ///
    /// Supported ev charger model as described in ``SupportedCharger``.
    var evChargerModel: SupportedCharger

    /// Specific Power Meter
    ///
    /// The specific power meter used for this charging system.
    let powerMeter: PowerMeter

    /// Power Meter Model
    ///
    /// Supported power meter model as described in ``SupportedPowerMeter``.
    /// - Note: When the charger integrated power meter is in use, the model member equals `.nope`. This
    /// means that no MID conforming power meter is in use!
    var powerMeterModel: SupportedPowerMeter

    /// Charging State
    var chargingState: ChargerState = .unknown
    var evState: EVState = .unknown

    init(evCharger: EVCharger, evChargerModel: SupportedCharger, powerMeter: PowerMeter, powerMeterModel: SupportedPowerMeter) {
        self.evCharger = evCharger
        self.evChargerModel = evChargerModel
        self.powerMeter = powerMeter
        self.powerMeterModel = powerMeterModel
    }



}
