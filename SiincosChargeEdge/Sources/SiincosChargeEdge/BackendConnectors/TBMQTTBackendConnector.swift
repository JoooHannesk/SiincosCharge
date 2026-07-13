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
enum TBMQTTTopics: String {
    case telemetryTopic = "v1/devices/me/telemetry"
    case rpcTopic = "v1/devices/me/rpc/request/+"
    case attributeTopic = "v1/devices/me/attributes"
}

class ThingsBoardBackend: BackendController {

    var client: TinyTBDeviceClient?
    let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoopGroupProvider: NIOEventLoopGroupProvider

    // MARK: - Protocol enforced Members

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
                self.subscribe(to: [.rpcTopic])
            },
            onError: { error in
                self.logger.error("\(LogMessages.mqttConnectionFailed)", metadata: ["error": "\(error.localizedDescription)"])
                // throw SystemError.mqttConnectError
                exit(1) // TODO: replace with a throwing error, therefore the TinyTBDeviceClient library needs to be updated
            }
        )
    }

    /// Shutdown Backend
    ///
    /// Disconnect client and shutdown backend gracefully
    func shutdown() throws {
        self.client?.disconnect()
        try self.eventLoopGroup.syncShutdownGracefully()
    }

    /// Update Charging Point Status
    ///
    /// Update Charging Point Status in ThingsBoard
    func updateChargingPointStatus(with cpsStatus: Set<ChargingPointStatus>) {
        for cpStatus in cpsStatus {
            if let msg = cpStatus.asSerializedJson {
                self.publish(message: msg, to: .telemetryTopic)
            }
        }
    }

    /// Update Charging System Information
    ///
    /// Update Charging System Information in ThingsBoard
    func updateChargingSystemInformation(with sysInfo: ChargingSystemInformation) {
        if let msg = sysInfo.asJson {
            self.publish(message: msg, to: .attributeTopic)
        }
    }

    // MARK: - Backend specific Methods

    /// Subscribe to MQTT topics
    private func subscribe(to topics: [TBMQTTTopics]) {
        self.client?.subscribe(
            to: topics.map { $0.rawValue },
            onSuccess: { topic, subAck in
                self.logger.info("\(LogMessages.mqttSubscriptionSuccess)\(topic) with code \(subAck)")
                self.setMessageListener()
            },
            onError: { error in
                self.logger.error("\(LogMessages.mqttSubscriptionFailed)", metadata: ["error": "\(error.localizedDescription)"])
            }
        )
    }

    /// Set a message listener
    ///
    /// Handle inbound messages (messages are related to subscribed topics)
    private func setMessageListener() {
        self.client?.registerMessageListener(
            named: "MainListener",
            onMessage: { [weak self] message, topic in
                print("Received: \(topic), \(message)")
            }, onError: { error in
                self.logger.error("\(LogMessages.mqttMessageHandlingFailed)", metadata: ["error": "\(error.localizedDescription)"])
            })
    }


    // MARK: - Private methods

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

    /// Publishes message to the specified MQTT topic.
    ///
    /// This method uses the configured MQTT client to publish a message
    /// to the given topic. It handles both success and error cases,
    /// logging appropriate messages to the console.
    ///
    /// - Parameters:
    ///   - message: The JSON string containing telemetry data to publish
    ///   - topic: The MQTT topic to which the message should be published
    ///
    /// - Note: This method relies on a shared `mqttClient` instance that must
    ///   be configured before calling this function. If the client is not set,
    ///   no message will be published.
    private func publish(message: String, to topic: TBMQTTTopics) {
        self.client?.publish(
            message: message,
            to: topic.rawValue,
            onSuccess: {
                //self.logger.info("Telemetry published: \(message)")
            },
            onError: { error in
                self.logger.error("Message \(message) failed to publish with error: \(error)")
            }
        )
    }

}
