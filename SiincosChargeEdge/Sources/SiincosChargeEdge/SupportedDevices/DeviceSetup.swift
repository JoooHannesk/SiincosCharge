//
//  DeviceSetup.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 01.04.26.
//

import ModbusSerial


/// Setup EV Charger and Power Meter
///
/// Setup EV chargers and power meters based on provided config
class DeviceSetup {
    private let logger = ComponentSupplier.mainLogger
    private let config: DeviceConfig
    var evChargers: [EVCharger] = []
    var powerMeters: [PowerMeter] = []

    init(config: DeviceConfig) {
        self.config = config
        self.setupEVChargers()
        self.setupPowerMeters()
    }

    private func setupEVChargers() {
        logger.info("Setting up Charger: \(self.config.chargerModel.rawValue)")
        self.evChargers.removeAll()
        self.powerMeters.removeAll()

        switch config.chargerModel {

        // MARK: - Chargers with integrated Power Meters
        case .mockCharger:
            (self.evChargers, self.powerMeters) = self.setupMockChargerWithPowerMeter(deviceConfig: self.config)

        case .senecWallboxProS11kW:
            (self.evChargers, self.powerMeters) = self.setupSenecWallboxProS11kW(deviceConfig: self.config)

        // MARK: - Chargers without integrated Power Meters


        // MARK: - Unsupported charger defined in configuration
        case .unknown:
            break
        }
    }

    private func setupPowerMeters() {
        logger.info(
            "Setting up Power Meter: \(self.config.meterModel.rawValue)"
        )
        switch config.meterModel {

        // MARK: - No external power meter in use
        case .nope:
            break

        // MARK: - Unsupported Power Meter defined in configuration
        case .unknown:
            break

        // MARK: - Setup for external power meter
        case .janitzaSmartMeterB2331210J:
            self.powerMeters.removeAll()
            self.powerMeters = self.setupJanitzaSmartMeterB2331210J(deviceConfig: self.config)
        }
    }


    /// Init Modbus RTU devices
    ///
    /// Initialze modbus rtu devices based on the `lineLenght` and
    /// `startAddress`.
    private func defineModbusRTUDeviceOnBus<T: ModbusRTUDevice>(deviceClient: ModbusRTUClient, lineLenght: UInt8, startAddress: UInt8 = 1, modelName: String) -> Array<T> {
        // TODO: improve documentation
        var devices: [T] = []
        // TODO: use closed range instead of half open range, this saves 1 line of code
        let upperBound = startAddress + lineLenght
        for uid in startAddress..<upperBound {
            print("UID: \(uid), Model Name: \(modelName)")
            devices.append(T(modbusRTUClient: deviceClient, unitId: uid, modelName: modelName))
        }
        return devices
    }

    // MARK: Specific device setup - EV Chargers

    /// Setup Mock Charger
    ///
    /// - Parameter deviceConfig: system device configuration
    /// - Returns: Tuple containing two arrays, the first holding the ``EVCharger``s and the
    /// second one holding the ``PowerMeter``s
    private func setupMockChargerWithPowerMeter(deviceConfig: DeviceConfig) -> ([EVCharger], [PowerMeter]) {
        var mockChargers: [MockCharger] = []
        var mockChargersWithPowerMeters: [MockChargerPowerMeter] = []

        let startAddress: UInt8 = 1
        let lineLength = deviceConfig.lineLength
        let upperBound = startAddress + lineLength
        for uid in startAddress..<upperBound {
            mockChargers.append(MockCharger(unitId: uid, modelName: deviceConfig.chargerModel))
            mockChargersWithPowerMeters.append(MockChargerPowerMeter(unitId: uid, modelName: deviceConfig.meterModel))
        }
        return (mockChargers, mockChargersWithPowerMeters)
    }

    /// Setup SenecWallboxProS11kW
    ///
    /// This EV charger has an integrated Power meter. Therefore,  setup both: the EV
    /// charger and the internal power meter.
    /// - Parameter deviceConfig: system device configuration
    /// - Returns: Tuple containing two arrays, the first holding the ``EVCharger``s and the
    /// second one holding the ``PowerMeter``s
    private func setupSenecWallboxProS11kW(deviceConfig: DeviceConfig) -> ([EVCharger], [PowerMeter]){
        let senecDeviceClient = SenecWallboxProS11kW.getModbusDeviceClient(serialPort: deviceConfig.chargerBus)
        let senecChargers: Array<SenecWallboxProS11kW> = self.defineModbusRTUDeviceOnBus(deviceClient: senecDeviceClient, lineLenght: deviceConfig.lineLength, modelName: deviceConfig.chargerModel.rawValue)
        let senecInternalPowerMeter: Array<SenecWallboxProSPowerMeter> = self.defineModbusRTUDeviceOnBus(deviceClient: senecDeviceClient, lineLenght: deviceConfig.lineLength, modelName: deviceConfig.meterModel.rawValue)
        return (senecChargers, senecInternalPowerMeter)
    }


    // MARK: Specific device setup - Dedicated Power Meters

    /// Setup Janitza Smar tMeter B23 312-10J
    ///
    /// - Parameter deviceConfig: system device configuration
    /// - Returns: Array with power meters
    private func setupJanitzaSmartMeterB2331210J(deviceConfig: DeviceConfig) -> [PowerMeter] {
        let janitzaDeviceClient = JanitzaSmartMeterB2331210J.getModbusDeviceClient(serialPort: deviceConfig.meterBus)
        let janitzaPowerMeters: Array<JanitzaSmartMeterB2331210J> = self.defineModbusRTUDeviceOnBus(deviceClient: janitzaDeviceClient, lineLenght: deviceConfig.lineLength, modelName: deviceConfig.meterModel.rawValue)
        return janitzaPowerMeters
    }
}
