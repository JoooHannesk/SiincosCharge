

import Testing
import ModbusSerial
@testable import SiincosChargeEdge


struct SiincosChargeEdgeTests {

    @Test("Load-System-Config-From-File")
    func loadConfig() async throws {
        let config = await ConfigLoader.getSystemConfig()
        #expect(config != nil)
        #expect(!config!.systemId.isEmpty)
        #expect(CompatibleCharger.allCases.contains(config!.chargerModel))
        #expect(CompatibleSmartMeter.allCases.contains(config!.meterModel))
    }

    /// Test logging to file
    ///
    /// Log a single line to file
    @Test("Log-Sample-Message-To-File")
    func logToFile() async throws {
        let logger = await FileLoggingConfiguration.shared.getLogger(for: "Tests")
        let logString = "This is a single log entry. This should be written in the log file."
        logger.info("\(logString)")
        logger.warning("\(logString)")
        logger.error("\(logString)", metadata: ["sampleMetaData": "This is a sample metadata test string."])
        await FileLoggingConfiguration.shared.close()
    }
}


