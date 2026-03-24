

import Testing
import ModbusSerial
@testable import SiincosChargeEdge


struct SiincosChargerGenericTests {

    // TODO: make dynamic by loading the config from file

    let unitId: UInt8
    let config: RTUClientConfiguration
    let modbusDevice: ModbusRTUClient
    let charger: CarCharger

    init() {
        // TODO: make dynamic by loading the config from file
        unitId = 1
        config = RTUClientConfiguration(
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
        modbusDevice = ModbusRTUClient(configuration: config)
        charger = SenecWallboxProS(modbusDevice: modbusDevice, unitId: unitId)
    }


    @Test("Run-All-Generic-Device-Tests")
    func runAllGenericDeviceTests() async throws {
        let genericDeviceTests = GenericChargerTestCases(charger: self.charger)
        try await genericDeviceTests.runAllTests()
    }
}


