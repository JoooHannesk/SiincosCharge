//
//  ChargingPointContainer.swift
//  SiincosCharge
//
//  Created by Johannes Kinzig on 25.05.26.
//

/// ChargingPointContainer
///
/// A container for multiple charging points that provides lookup by unit identifier (`cpId`).
///
/// - Note: Some Modbus RTU devices don't support the full unit‑ID range (1…247). Certain IDs can be
/// reserved or unsupported, so the device at the first physical position on the bus might not
/// be addressable with unit ID 1.
/// Because of these constraints, the `chargingPoints` array index cannot be assumed to match a
/// device's unit ID. Instead, access charging points by explicitly comparing their `cpId` using
/// the provided async subscript or `getChargingPoint(by:)`.
actor ChargingPointContainer {
    private(set) var chargingPoints: [UInt8: ChargingPoint] = [:]
    private(set) var chargingTasks: [UInt8: ChargingSession] = [:]

    var count: Int {
        chargingPoints.count
    }

    /// Return charging point and task by index
    ///
    /// - Parameter cpId: Charging point id
    subscript(cpId: UInt8) -> (chargingPoint: ChargingPoint?, chargingTask: ChargingSession?)  {
        get async {
            let cPcT: (chargingPoint: ChargingPoint?, chargingTask: ChargingSession?) = (getChargingPoint(by: cpId), getChargingTask(by: cpId))
            return cPcT
        }
    }

    init(chargingPoints: [ChargingPoint]? = nil) async {
        if let chargingPoints {
            for cp in chargingPoints {
                await self.chargingPoints[cp.cpId] = cp
            }
        }
    }

    /// Add a new charging point
    ///
    /// Add a new charging point
    func addChargingPoint(_ cp: ChargingPoint) async {
        await self.chargingPoints[cp.cpId] = cp
    }

    /// Get charging point by ID
    ///
    /// Get charging point by its id.
    /// - Parameter cpId: Charging Point Id
    /// - Returns: the requested ``ChargingPoint`` (if no charging point with the given `cpId` exists, nil is returned)
    func getChargingPoint(by cpId: UInt8) -> ChargingPoint? {
        return self.chargingPoints[cpId]
    }

    /// Add new charging task
    ///
    /// Add a new charging task
    func addChargingTask(_ ct: ChargingSession) {
        self.chargingTasks[ct.cpId] = ct
    }

    /// Get charging task by ID
    ///
    /// Get charging task by its id.
    /// - Parameter cpId: Charging Point Id
    /// - Returns: the requested ``ChargingTask`` (if no charging point with the given `cpId` exists, nil is returned)
    func getChargingTask(by cpId: UInt8) -> ChargingSession? {
        return self.chargingTasks[cpId]
    }

}
