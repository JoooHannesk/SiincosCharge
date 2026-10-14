//
//  GPIODataModels.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 14.10.26.
//


/// Pin state representing a GPIOs logical level
enum PinState {
    case high
    case low
}



protocol GpioHandler {
    func getPinState() throws -> PinState
}
