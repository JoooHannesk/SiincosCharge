import Testing
import Foundation
@testable import SiincosChargeEdge


/// Siincos Charge Edge Tests
///
/// - Note: As the tests involve device communication via ModbusRTU/TCP, they have to be serialized.
/// Both, ModbusTCP and ModbusRTU are not designed to handle multiple connections in parallel.
@Suite("Siincos-Charge-Edge-Tests", .serialized)
struct SiincosChargeEdgeTests {

    @Test("Test-Average-Current-Calculation")
    func averageCurrent() {
        let testValueFrame = [
            // ([L1, L2, L3], expected)
            ([6.0, 6.0, 6.0], 6.0),
            ([6.0, 0.0, 6.0], 6.0),
            ([4.0, 3.0, 2.0], 3.0),
            ([4.0, 0.0, 2.0], 3.0),
            ([2.5, 5.5, 0.0], 4.0),
            ([2.5, nil, 2.5], 2.5),
            ([3.0, 9.0, nil], 6.0),
            ([3.0, 0.0, nil], 3.0),
            ([3.0, nil, nil], 3.0),
            ([4.5, 0.0, 0.0], 4.5),
            ([8.8, 0.0, 0.0], 8.8),
            ([8.8, nil, nil], 8.8),
        ]
        for testValue in testValueFrame {
            let current = ElectricCurrent3PhaseGrid(
                currentL1: testValue.0[0] != nil ? Measurement(value: testValue.0[0]!, unit: .amperes) : nil,
                currentL2: testValue.0[1] != nil ? Measurement(value: testValue.0[1]!, unit: .amperes) : nil,
                currentL3: testValue.0[2] != nil ? Measurement(value: testValue.0[2]!, unit: .amperes) : nil,
                )
            #expect(current.currentAverage.value == testValue.1)
        }
    }

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
    @Test("Log-Sample-Message-To-File", .disabled())
    func logToFile() async throws {
        let logger = FileLoggingConfiguration.shared.getLogger(for: "Tests")
        let logString = "This is a single log entry. This should be written in the log file."
        logger.info("\(logString)")
        logger.warning("\(logString)")
        logger.error("\(logString)", metadata: ["sampleMetaData": "This is a sample metadata test string."])
        await FileLoggingConfiguration.shared.close()
    }


    /// Test Main App
    ///
    /// This test case starts the main app's environment and terminates after 30 seconds.
    /// See this test as a first smoke test to ensure everything inits correctly.
    @Test("Test-Main-App")
    func testMainApp() async throws {
        let siincosChargeEdge = await ChargingController()
        try? await Task.sleep(for: .seconds(30))
    }
}


