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
    private let config: DeviceConfig
    var evChargers: [EVCharger] = []
    var powerMeters: [PowerMeter] = []

    init(config: DeviceConfig) {
        self.config = config
        self.setupEVChargers()
        self.setupPowerMeters()
    }

    private func setupEVChargers() {
        self.evChargers.removeAll()
        self.powerMeters.removeAll()

        switch config.chargerModel {

            // Chargers with integrated power meters
            case .senecWallboxProS11kW:
                let senecWallboxProS11kW = self.setupSenecWallboxProS11kW(deviceConfig: self.config)
                self.evChargers = senecWallboxProS11kW.0
                self.powerMeters = senecWallboxProS11kW.1

            // Chargers without integrated power meter

            }
    }

    private func setupPowerMeters() {
        switch config.meterModel {
            case .nope:
                break

            // Setup more power meters here
            //self.powerMeters.removeAll()
            }
    }


    /// Init Modbus RTU devices
    ///
    /// Initialze modbus rtu devices based on the `lineLenght` and
    /// `startAddress`.
    private func defineModbusRTUDeviceOnBus<T: ModbusRTUDevice>(deviceClient: ModbusRTUClient, lineLenght: UInt8, startAddress: UInt8 = 1) -> Array<T> {
        var devices: [T] = []
        let upperBound = startAddress + lineLenght
        for uid in startAddress..<upperBound {
            print("UID: \(uid)")
            devices.append(T(modbusRTUClient: deviceClient, unitId: uid))
        }
        return devices
    }

    // MARK: Specific device setup

    /// Setup SenecWallboxProS11kW
    ///
    /// This EV charger has an integrated Power meter. Therefore,  setup both: the EV
    /// charger and the internal power meter.
    /// - Parameter deviceConfig: system device configuration
    /// - Returns: Tuple containing two arrays, the first holding the ``EVCharger``s and the
    /// second one holding the ``PowerMeter``s
    private func setupSenecWallboxProS11kW(deviceConfig: DeviceConfig) -> ([EVCharger], [PowerMeter]){
        let senecDeviceClient = SenecWallboxProS11kW.getModbusDeviceClient(serialPort: deviceConfig.chargerBus)
        let senecChargers: Array<SenecWallboxProS11kW> = self.defineModbusRTUDeviceOnBus(deviceClient: senecDeviceClient, lineLenght: deviceConfig.lineLength)
        let senecInternalPowerMeter: Array<SenecWallboxProSPowerMeter> = self.defineModbusRTUDeviceOnBus(deviceClient: senecDeviceClient, lineLenght: deviceConfig.lineLength)
        return (senecChargers, senecInternalPowerMeter)
    }
}
