

import Testing
import ModbusSerial
@testable import SiincosChargeEdge


struct SiincosChargeEdgeTests {

    /// Test Component Supplier
    ///
    /// Test component supplier to deliver the configuration
    /// instance as described by the configuration file.
    @Test("Load-System-Config-From-File")
    func loadConfig() async throws {
        let config = try ComponentSupplier.getSystemConfig()
        #expect(!config.systemId.isEmpty)
        #expect(SupportedCharger.allCases.contains(config.chargerModel))
        #expect(SupportedPowerMeter.allCases.contains(config.meterModel))
    }

    /// Test Component Supplier
    ///
    /// Test component supplier to deliver the devices as requested
    /// by the configuration file.
    @Test("Configure-Devices")
    func configureDevices() throws {
        let config = try ComponentSupplier.getSystemConfig()
        let (chargers, powerMeters) = try ComponentSupplier.getDevices(for: config)
        #expect(!chargers.isEmpty && !powerMeters.isEmpty)
    }

    /// Test logging to file
    ///
    /// Log a single line to file
    @Test("Log-Sample-Message-To-File")
    func logToFile() async throws {
        let logger = FileLoggingConfiguration.shared.getLogger(for: "Tests")
        let logString = "This is a single log entry. This should be written in the log file."
        logger.info("\(logString)")
        logger.warning("\(logString)")
        logger.error("\(logString)", metadata: ["sampleMetaData": "This is a sample metadata test string."])
        await FileLoggingConfiguration.shared.close()
    }
}


