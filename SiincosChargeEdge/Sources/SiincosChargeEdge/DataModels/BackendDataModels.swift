//
//  BackendController.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 02.06.26.
//


import Logging


/// Backend Controller
///
/// Backend Controller protocol predefining functionality which is exposed to
/// a local or remote backend
protocol BackendController {

    /// Charging Controller
    ///
    /// Charging controller responsible fot managing the local charging system
    var chargingController: ChargingController { get }

    /// Logger
    var logger: Logger { get }

    init(chargingController: ChargingController)

    /// Start Backend Controller
    func startup() throws

    /// Shutdown Backend Controller
    ///
    /// Shutdown Backend Controller gracefully
    func shutdown() throws

    /// Update Charging System Status
    ///
    /// Propagate charging system status to backend
    func updateChargingSystemStatus()

    /// Update Charging System Information
    ///
    /// Propagate charging system information to backend
    func updateChargingSystemInformation(with sysInfo: ChargingSystemInformation)
}

