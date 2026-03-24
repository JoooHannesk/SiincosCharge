

import Testing
import ModbusSerial
@testable import SiincosChargeEdge


/// Device Tests Senec Wallbox Pro S
///
/// Specific device tests for the charger Wallbox Pro S from SENEC.
/// To run this test, a physical charger is required.
class DeviceIntegrationTestsSenecWallboxProS {
    // TODO: Implement as a flexible solution which takes the connection settings from the config file


    static let unitId: UInt8 = 1
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
    static let deviceClient = ModbusRTUClient(configuration: config)
    static let charger = SenecWallboxProS(modbusDevice: deviceClient, unitId: unitId)

    @Test("Get-Charging-State")
    func getChargingState() async throws {
        let state = try await Self.charger.getChargingState()
        #expect(state != .unknown)
        print(state)
    }

}
