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

    static let config = RTUClientConfiguration(
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

    static func main() {
        print("Hello, world!")
        Task {
            try! await readData()
        }

        dispatchMain()
    }

    static func readData() async throws {
        let client = ModbusRTUClient(configuration: config)
        try await client.connect()
        var response = try await client.readHoldingRegisters(address: 259, count: 1, unitId: 1)
        print(response.signedValue(at: 0))
        let writeResponse = try await client.writeSingleRegister(address: 259, value: 1, unitId: 1)
        print(writeResponse)
        response = try await client.readHoldingRegisters(address: 259, count: 1, unitId: 1)
        print(response.signedValue(at: 0))
        await client.close()
    }

}
