//
//  TBMQTTBackendConnector.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 02.06.26.
//


/// MQTT Topics
///
/// Topics required to communicate with ThingsBoard MQTT Server
enum MQTTTopics {
    static let telemetryTopic = "v1/devices/me/telemetry"
    static let rpcTopic = "v1/devices/me/rpc/request/+"
    static let attributeTopic = "v1/devices/me/attributes"
}

class ThingsBoardBackend: BackendController {
    
    let chargingController: ChargingController

    required init(chargingController: ChargingController) {
        self.chargingController = chargingController
    }

    func startup() throws {
        // TODO: implement correctly
        print("Starting up!")
    }
    
    func shutdown() {
        // TODO: implement correctly
        print("Shuttting Down!")
    }

    func updateChargingSystemStatus() {
        // TODO: implement
    }

    func updateChargingSystemInformation(with sysInfo: ChargingSystemInformation) {
        print(sysInfo)
    }

}
