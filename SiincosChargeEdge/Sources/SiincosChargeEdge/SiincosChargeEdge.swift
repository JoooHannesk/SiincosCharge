//
//  SiincosChargeEdge.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 23.03.26.
//

import Foundation

@main
struct SiincosChargeEdge {
    static func main() async {

        let siincosChargeEdge = await ChargingController()
        while true { try? await Task.sleep(nanoseconds: 60 * 1_000_000_000) }
    }
}
