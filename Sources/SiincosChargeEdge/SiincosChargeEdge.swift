//
//  SiincosChargeEdge.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 23.03.26.
//

import ModbusSerial
import Foundation

@main
struct SiincosChargeEdge {
    static func main() async {
        print("Hello, world!")

        // TODO: remove after test!

        let unitId: UInt8 = 1
        let config = RTUClientConfiguration(
            serialConfiguration: SerialConfiguration(
                port: "/dev/tty.usbserial-AB0O6Z7W",
                baudRate: .b19200,
                parity: .even,
                stopBits: .one,
                dataBits: .eight,
                timeout: .seconds(3)
            ),
            retries: 3,
            errorRecovery: .exponentialBackoff(
                initialDelay: .milliseconds(500),
                maxDelay: .seconds(10)
            ),
            handleLocalEcho: false  // For RS-485 half-duplex adapters
        )
        let modbusDevice = ModbusRTUClient(configuration: config)
        let charger = SenecWallboxProS11kW(modbusRTUClient: modbusDevice, unitId: unitId)

        while true {
            print(try! await charger.getChargerState())
            try! await Task.sleep(for: .seconds(2))
            print(try! await charger.setSoftwareLock(to: .unlocked))
            print(try! await charger.setMaxCurrentLimitSetpoint(to: Measurement(value: 16.0, unit: UnitElectricCurrent.amperes)))
        }
    }
}
