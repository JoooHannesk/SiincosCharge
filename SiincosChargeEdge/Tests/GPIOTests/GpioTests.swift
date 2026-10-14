//
//  GpioTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 14.10.26.
//

import Testing
@testable import SiincosChargeEdge

/// Test suite to test the systems GPIO digital inputs provided through
/// `gpioget`.
///
/// When testing on a system where `gpioget` is unavailable, make sure to initialize
/// the simulator beforehand. Refer to the documentation *Development Documentation*
/// section *Simulating digital inputs on the GPIOs* for setting up a (wannabe) GPIO simulator.
///
/// On systems where `gpioget` is natively unsupported initailize the gpio simulator as follows:
/// ```bash
/// # init gpio simulator
/// fakegpio init 18 19
///
/// # toggle simulated pin
/// fakegpio toggle 18
/// fakegpio toggle 19
///
/// # set/reset simulated pin
/// fakegpio set 18 1
/// fakegpio set 19 0
/// ```
@Suite("GPIO Tests with gpioget", .serialized)
struct GpiogetTests {
    
    @Test("Check for valid state")
    func checkForValidState() throws {
        let gpio18 = RaspiGPIOReader(gpiochip: .chip0, pin: 18)
        let state = try gpio18.read()
        #expect(state == .high || state == .low)
    }
}

