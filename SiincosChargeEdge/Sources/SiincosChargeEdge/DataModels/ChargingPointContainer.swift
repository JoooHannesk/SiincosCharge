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
struct ChargingPointContainer {
    private var chargingPoints: [ChargingPoint]

    var count: Int {
        chargingPoints.count
    }

    subscript(cpId: UInt8) -> ChargingPoint? {
        get async {
            return await getChargingPoint(by: cpId)
        }
    }

    init(chargingPoints: [ChargingPoint]? = nil) {
        if let chargingPoints {
            self.chargingPoints = chargingPoints
        } else {
            self.chargingPoints = []
        }
    }

    /// Add a new charging point
    mutating func addChargingPoint(_ cp: ChargingPoint) {
        self.chargingPoints.append(cp)
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
}
