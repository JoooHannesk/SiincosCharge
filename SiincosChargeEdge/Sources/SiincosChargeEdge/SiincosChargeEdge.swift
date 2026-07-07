//
//  SiincosChargeEdge.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 23.03.26.
//

import Foundation

@main
struct SiincosChargeEdge {

    @MainActor static var shutdownRequested = false

    static func main() async {

        PosixSignals.registerTerminationHandler(run: {
            self.shutdownRequested = true
        })

        let siincosChargeEdge = await ChargingController()

        while !Self.shutdownRequested {
            try? await Task.sleep(for: .seconds(5))
        }

        await siincosChargeEdge.shutdown()
    }
}
