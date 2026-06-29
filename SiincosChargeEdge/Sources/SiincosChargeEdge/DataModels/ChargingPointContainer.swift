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
    private(set) var chargingPoints: [ChargingPoint] = []
    private(set) var chargingTasks: [ChargingTask] = []

    var count: Int {
        chargingPoints.count
    }

    /// Return charging point and task by index
    ///
    /// - Parameter cpId: Charging point id
    subscript(cpId: UInt8) -> (chargingPoint: ChargingPoint?, chargingTask: ChargingTask?)  {
        get async {
            let cPcT: (chargingPoint: ChargingPoint?, chargingTask: ChargingTask?) = (await getChargingPoint(by: cpId), await getChargingTask(by: cpId))
            return cPcT
        }
    }

    init(chargingPoints: [ChargingPoint]? = nil, chargingTasks: [ChargingTask]? = nil) {
        if let chargingPoints {
            self.chargingPoints = chargingPoints
        }
        if let chargingTasks {
            self.chargingTasks = chargingTasks
        }
    }

    /// Add a new charging point
    ///
    /// Add a new charging point and corresponding charging task
    func addChargingPoint(_ cp: ChargingPoint) async {
        self.chargingPoints.append(cp)
        await self.chargingTasks.append(ChargingTask(cpId: cp.cpId))
    }

    /// Get charging point by ID
    ///
    /// Get charging point by its id.
    /// - Parameter cpId: Charging Point Id
    /// - Returns: the requested ``ChargingPoint`` (if no charging point with the given `cpId` exists, nil is returned)
    func getChargingPoint(by cpId: UInt8) async -> ChargingPoint? {
        for cp in chargingPoints {
            if await cp.cpId == cpId {
                return cp
            }
        }
        return nil
    }

    /// Get charging task by ID
    ///
    /// Get charging task by its id.
    /// - Parameter cpId: Charging Point Id
    /// - Returns: the requested ``ChargingTask`` (if no charging point with the given `cpId` exists, nil is returned)
    func getChargingTask(by cpId: UInt8) async -> ChargingTask? {
        for ct in chargingTasks {
            if ct.cpId == cpId {
                return ct
            }
        }
        return nil
    }

}
