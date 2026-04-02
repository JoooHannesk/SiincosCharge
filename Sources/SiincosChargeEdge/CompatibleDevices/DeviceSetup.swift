//
//  DeviceSetup.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 01.04.26.
//

import ModbusSerial


/// Setup EV Charger and Power Meter
///
/// Setup EV charger and power meter based on provided config
class DeviceSetup {
    let config: DeviceConfig
    var evChargers: [EVCharger] = []
    var powerMeters: [PowerMeter] = []

    init(config: DeviceConfig) {
        self.config = config
    }

    /// Setup devices
    ///
    /// Evaluate device config and setup EV charger and
    /// power meter accordingly.
    private func setupDevices() {
        switch config.chargerModel {
        case .senecWallboxProS11kW:
            let senecDeviceClient = SenecWallboxProS11kW.getModbusDeviceClient(serialPort: config.chargerBus)
            let senecCharger: Array<SenecWallboxProS11kW> = self.defineModbusRTUDeviceOnBus(deviceClient: senecDeviceClient, lineLenght: config.lineLength)

        }
    }

    func getEVChargers() { //-> [EVCharger] {

    }

    func getPowerMeters() { // -> [PowerMeter] {

    }

    private func defineModbusRTUDeviceOnBus<T: ModbusRTUDevice>(deviceClient: ModbusRTUClient, lineLenght: UInt8, startAddress: UInt8 = 1) -> Array<T> {
        var devices: [T] = []
        let upperBound = startAddress + lineLenght
        for uid in startAddress..<upperBound {
            print("UID: \(uid)")
            devices.append(T(modbusRTUClient: deviceClient, unitId: uid))
        }
        return devices
    }
}
