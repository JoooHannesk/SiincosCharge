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
    case gwAnnounceDevice = "v1/gateway/connect"
    case gwTelemetryTopic = "v1/gateway/telemetry"
    case gwRPCTopic = "v1/gateway/rpc/request/+"
    case gwAttributeTopic = "v1/gateway/attributes"

    case dvcAttributeTopic = "v1/devices/me/attributes"
    case dvcTelemetryTopic = "v1/devices/me/telemetry"
    case dvcRPCTopic = "v1/devices/me/rpc/request/+"
}

/// ThingsBoard Identifiers
///
/// Identifiers to control ThingsBoard specific behavior
enum TBIdentifiers: String {
    case deviceProfileName = "SiincosChargeEdge"
}

/// ThingsBoard message format selector
enum TBMessageFormat {
    case attribute
    case telemetry
}

enum SupportedRPC: String, Codable {
    case requestChargingSession
}

class ThingsBoardBackend: BackendController, @unchecked Sendable {

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
        self.client?.enableAutoReconnect()
        self.client?.connect(
            onSuccess: {
                self.logger.info("\(LogMessages.mqttConnectionSuccess)")
                self.announceChargingPoints()
                self.subscribe(to: [.gwRPCTopic])
            },
            onError: { error in
                self.logger.error("\(LogMessages.mqttConnectionFailed)", metadata: ["error": "\(error.localizedDescription)"])
                ChargingController.shutdown(exitCode: 1)
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
            if let msg = cpStatus.asJson {
                self.publish(message: msg, to: cpStatus.cpId, with: .gwTelemetryTopic, as: .telemetry)
            }
        }
    }

    /// Update Charging System Information
    ///
    /// Update Charging System Information in ThingsBoard
    func updateChargingSystemInformation(with sysInfo: ChargingSystemInformation) {
        if let msg = sysInfo.asJson {
            self.publish(message: msg, to: .dvcAttributeTopic)
            Task { [chargingController] in
                if let chargingPoints = await chargingController.chargingSystem?.chargingPointContainer.chargingPoints.values {
                    for cp in chargingPoints {
                        await self.publish(message: msg, to: cp.cpId, with: .gwAttributeTopic, as: .attribute)
                    }
                }
            }
        }
    }

    /// Update Charging Sessions
    ///
    /// Update charging sessions in backend
    /// - Parameter chargingPointIds: Collection containing all registered charging point IDs
    /// - Parameter chargingSessions: Collection containing all charging sessions
    func updateChargingSessions(chargingPointIds: some Collection<UInt8>, chargingSessions: some Collection<ChargingSession>) {
//        for cpId in chargingPointIds {
//            var sessionMessage = ""
//            if let session = chargingSessions.first(where: { $0.cpId == cpId }) {
//                sessionMessage = #"{"cp\#(cpId)_session": \#(session.asJson, default: "")}"#
//            } else {
//                sessionMessage = #"{"cp\#(cpId)_session": ""}"#
//            }
//            self.publish(message: sessionMessage, to: .attributeTopic)
//        }
    }

    /// Write a charging session receipt
    ///
    /// Generate a charging session receipt for the finished charging session. Persist the receipt according to
    /// the backend implementation
    ///
    /// - Parameter session: The charging session to write the receipt for
    func writeChargingSessionReceipt(for session: ChargingSession) {
//        let sessionReceiptMessage = #"{"cp\#(session.cpId)_sessionReceipt": \#(session.asJson, default: "")}"#
//        self.publish(message: sessionReceiptMessage, to: .telemetryTopic)
    }

    /// Asynchronously announces all available charging points to the ThingsBoard gateway.
    ///
    /// This method iterates through all charging points currently managed by the `chargingController`.
    /// For each charging point, it:
    /// 1. Resolves the device name (e.g., "CP_1").
    /// 2. Constructs a JSON announcement message specifying the device name and its profile type.
    /// 3. Publishes the message to the gateway's device announcement topic (`gw/connect`).
    ///
    /// This registration step is required by the ThingsBoard Gateway to ensure that data
    /// sent for these specific devices is correctly mapped and processed in the backend.
    private func announceChargingPoints() {
        Task { [chargingController] in
            if let chargingPoints = await chargingController.chargingSystem?.chargingPointContainer.chargingPoints.values {
                for cp in chargingPoints {
                    let cpName = await self.getChargingPointName(cpId: cp.cpId)
                    let announceCpMsg = #"{"device": "\#(cpName)", "type": "\#(TBIdentifiers.deviceProfileName.rawValue)"}"#
                    self.publish(message: announceCpMsg, to: .gwAnnounceDevice)
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Publishes a message to a specific ThingsBoard device managed by this gateway.
    ///
    /// This convenience method wraps the device-specific message (attribute or telemetry) in the
    /// appropriate JSON format and publishes it to the specified topic. The message is automatically mapped to the correct
    /// ThingsBoard device using the charging point ID.
    ///
    /// - Parameters:
    ///   - message: The JSON string containing the data to publish
    ///   - device: The charging point ID (used to identify the target device)
    ///   - topic: The ThingsBoard MQTT topic to publish to
    private func publish(message: String, to device: UInt8, with topic: TBMQTTTopics, as msgFormat: TBMessageFormat) {
        let cpName = self.getChargingPointName(cpId: device)
        var dvcMsg: String = ""
        switch msgFormat {
        case .attribute:
            dvcMsg = #"{"\#(cpName)": \#(message)}"#
        case .telemetry:
            dvcMsg = #"{"\#(cpName)": [\#(message)]}"#
        }
        self.publish(message: dvcMsg, to: topic)
    }

    /// Returns the canonical ThingsBoard name for a charging point.
    ///
    /// Formats the name as `{systemId}-CP{cpId}`, which is used as the device key
    /// when publishing telemetry so ThingsBoard maps attributes or telemetry to the correct device.
    /// - Parameter cpId: The charging point identifier.
    /// - Returns: A string in the format `{systemId}-CP{cpId}`.
    private func getChargingPointName(cpId: UInt8) -> String {
        let systemId = chargingController.systemConfig.systemId
        let cpName = "\(systemId)-CP-\(cpId)"
        return cpName
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

    // MARK: - Private methods

    /// Message Processor
    ///
    /// Process incoming message by calling corresponding method from ``ChargingController``
    private func messageProcessor(message: String, topic: String? = nil) {
        do {
            guard let msgData = message.data(using: .utf8) else {
                self.logger.warning("\(LogMessages.dataConversionFailed)")
                return
            }
            guard let msgDict = try JSONSerialization.jsonObject(with: msgData) as? [String: Any] else {
                self.logger.warning("\(LogMessages.dataConversionFailed)")
                return
            }
            let method = (msgDict["method"] as? String).flatMap(SupportedRPC.init(rawValue:))
            switch method {
            case .requestChargingSession:
                if let chargingSession: ChargingSession = try self.decodeMessagePayload(msgDict: msgDict) {
                    Task { [chargingController] in
                        await chargingController.requestChargingSession(chargingSession)
                    }
                }
            default:
                break
            }
        } catch {
            self.logger.warning("\(LogMessages.dataConversionFailed)", metadata: ["error": "\(error.localizedDescription)"])
        }
    }

    /// Set a message listener
    ///
    /// Handle inbound messages (messages are related to subscribed topics)
    private func setMessageListener() {
        self.client?.registerMessageListener(
            named: "MainListener",
            onMessage: { message, topic in
                self.messageProcessor(message: message, topic: topic)
            }, onError: { error in
                self.logger.error("\(LogMessages.mqttMessageHandlingFailed)", metadata: ["error": "\(error.localizedDescription)"])
            })
    }

    /// Decode RPC message payload
    ///
    /// Decode the `params` field of an RPC message into the inferred `Codable` type.
    /// - Parameter msgDict: RPC message as dictionary, containing a `params` field with the payload
    /// - Returns: Decoded payload object, or `nil` if the message contains no `params` field
    /// - Throws: An error if serialization or decoding of the payload fails
    private func decodeMessagePayload<T: Codable>(msgDict: [String: Any]) throws -> T? {
        if let paramsData = msgDict["params"] as? [String: Any] {
            let paramsJson = try JSONSerialization.data(withJSONObject: paramsData)
            let payloadObject = try JSONDecoder.customTelemetryCompatibleDecoder.decode(T.self, from: paramsJson)
            return payloadObject
        } else {
            return nil
        }
    }

    /// Create MQTT Client
    ///
    /// Create client from config provided through ``ThingsBoardBackend/chargingController``.
    /// - Returns: MQTT client
    /// - Throws: An error if instantiating of ``TinyTBDeviceClient``
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
            logger: self.logger,
            exhaustiveLogging: false
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
        guard let client = self.client, client.isConnected else {
            return
        }
        client.publish(
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
