//
//  LogMessages.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 03.06.26.
//

import Foundation

enum LogMessages {
    static let welcomMsg = "Hello, I am SiincosChargeEdge charging controller. – My PID is: \(getpid())"
    static let goodbyMsg = "Shutting down... Goodbye!"
    static let restartMsg = "Restarting... See you soon!"
    static let sysInfo = "System information:"
    static let dataConversionFailed = "Failed to convert message to object."
    static let chargingSessionRequest = "Charging session requested: "
    static let mqttConnectionSuccess = "✓ Successfully connected to MQTT broker."
    static let mqttConnectionFailed = "⨯ Failure connecting to MQTT broker."
    static let mqttSubscriptionSuccess = "✓ Successfully subscribed to topics:"
    static let mqttSubscriptionFailed = "⨯ Failure subscribing to topics:"
    static let mqttMessageHandlingFailed = "⨯ Failure when handling MQTT message!"
}
