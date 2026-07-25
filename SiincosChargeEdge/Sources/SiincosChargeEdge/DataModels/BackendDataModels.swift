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

    /// Update Charging Point Status
    ///
    /// Propagate charging system status to backend
    func updateChargingPointStatus(with cpsStatus: Set<ChargingPointStatus>)

    /// Update Charging System Information
    ///
    /// Propagate charging system information to backend
    func updateChargingSystemInformation(with sysInfo: ChargingSystemInformation)

    /// Update Charging Sessions
    ///
    /// Update charging sessions in backend
    /// - Parameter chargingPointIds: Array containing all registered charging point IDs
    /// - Parameter chargingSessions: Array containing all charging sessions
    func updateChargingSessions(chargingPointIds: [UInt8], chargingSessions: [ChargingSession])


    /// Write a charging session receipt
    ///
    /// Generate a charging session receipt for the finished charging session. Persist the receipt according to
    /// the backend implementation
    ///
    /// - Parameter session: The charging session to write the receipt for
    func writeChargingSessionReceipt(for session: ChargingSession)
}

