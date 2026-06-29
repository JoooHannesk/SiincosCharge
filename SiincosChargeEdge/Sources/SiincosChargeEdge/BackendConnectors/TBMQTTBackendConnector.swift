//
//  TBMQTTBackendConnector.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 02.06.26.
//


import TinyTBDeviceClient
import NIO
import Foundation


/// ThingsBoard MQTT Topics
///
/// Topics required to communicate with ThingsBoard MQTT Server
enum TBMQTTTopics {
    static let telemetryTopic = "v1/devices/me/telemetry"
    static let rpcTopic = "v1/devices/me/rpc/request/+"
    static let attributeTopic = "v1/devices/me/attributes"
}

class ThingsBoardBackend: BackendController {

    var client: TinyTBDeviceClient?
    let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoopGroupProvider: NIOEventLoopGroupProvider

    let chargingController: ChargingController

    /// Logger
    ///
    /// The application-wide main logger
    let logger = ComponentSupplier.mainLogger

    required init(chargingController: ChargingController) {
        self.chargingController = chargingController
        self.eventLoopGroupProvider = .shared(eventLoopGroup)
    }

    /// Startup
    ///
    /// Prepare client and connect to MQTT broker.
    func startup() throws {
        self.client = try self.createMQTTClient()
        self.client?.connect(
            onSuccess: {
                self.logger.info("\(LogMessages.mqttConnectionSuccess)")
            },
            onError: { error in
                self.logger.error("\(LogMessages.mqttConnectionFailed)", metadata: ["error": "\(error.localizedDescription)"])
            }
        )
    }
    
    func shutdown() throws {
        try self.eventLoopGroup.syncShutdownGracefully()
        // TODO: implement correctly
        print("Shuttting Down!")
    }

    func updateChargingSystemStatus() {
        // TODO: implement
    }

    func updateChargingSystemInformation(with sysInfo: ChargingSystemInformation) {
        // TODO: implement correctly
        // store as attributes in TB, each is a single attribute
        print(sysInfo)
    }

    // MARK: - private methods

    /// Create MQTT Client
    ///
    /// Create client from config provided through ``ThingsBoardBackend/chargingController``.
    /// - Returns: MQTT client
    private func createMQTTClient() throws -> TinyTBDeviceClient? {
        let config = self.chargingController.systemConfig
        client = try TinyTBDeviceClient(
            host: config.cloudHost,
            port: Int(config.cloudPort) as Int,
            clientId: config.cloudClientId,
            caCertPath: config.cloudCACertPath,
            username: config.cloudUsername,
            password: config.cloudPassword,
            eventLoopGroupProvider: self.eventLoopGroupProvider,
            logger: self.logger
        )
        return client
    }
}
