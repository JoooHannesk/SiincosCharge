//
//  DeviceIntegrationTestsSenecWallboxProS.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 24.03.26.
//

import Testing
import ModbusSerial
@testable import SiincosChargeEdge


/// Senec Wallbox Pro S Device Test Cases
///
/// Specific device tests for the charger Wallbox Pro S from SENEC.
/// To run this test, a physical charger is required.
class SenecWallboxProSTestCases {
    let charger: SenecWallboxProS

    init(charger: SenecWallboxProS) {
        self.charger = charger
    }
}
