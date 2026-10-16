//
//  ExternalGPIOLoadLimiter.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 15.10.26.
//


/// The external load limiter provides access to external load limiting signals via GPIOs
/// (electrically connected to the device e.g. as dry-contact, or similar).
///
/// Assume running SiincosChargeEdge on the reComputer featuring two digital inputs, which are used as follows:
///
/// | physical input pin  |   Purpose   | sysfs convention  |      chip      | `gpioget` convention  |
/// | ------------------ | ----------  | -----------------  | ----------  | -----------------------   |
/// | DI 1                         |  cut off       | GPIO 530              | gpiochip0  |           18                            |
/// | DI 2                         |  derating    | GPIO 531              | gpiochip0  |           19                            |
///
final class ReComputerDIGPIOLoadLimiter: ExternalLoadLimiter {
    
    private let extCutOffSignalProvider: GpioController
    private let extDeratingSignalProvider: GpioController
    
    /// Current load limiting signal provided
    /// Required by protocol ``ExternalLoadLimiterSignalHandler``
    var loadLimitingSignal: LoadLimiterSignal {
        get throws {
            let cutOffPinState = try self.extCutOffSignalProvider.getPinState()
            let deratingPinState = try self.extDeratingSignalProvider.getPinState()
            if cutOffPinState == .high {
                return .cutOff
            } else if deratingPinState == .high {
                return .derating(nil)
            } else {
                return .normalOperation
            }
        }
    }
    
    init(cutOffPin: UInt8 = 18, deratingPin: UInt8 = 19) {
        self.extCutOffSignalProvider = RaspiGPIOController(gpiochip: .chip0, pin: cutOffPin)
        self.extDeratingSignalProvider = RaspiGPIOController(gpiochip: .chip0, pin: deratingPin)
    }
}
