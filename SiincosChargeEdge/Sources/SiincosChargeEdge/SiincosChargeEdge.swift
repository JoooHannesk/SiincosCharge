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
        await siincosChargeEdge.startup()
        await siincosChargeEdge.run()
        
    }
}
