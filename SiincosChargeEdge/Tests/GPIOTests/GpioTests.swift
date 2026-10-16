//
//  GpioTests.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 14.10.26.
//

import Testing
@testable import SiincosChargeEdge
import Foundation


/// Test suite to test the systems GPIO digital inputs provided through
/// `gpioget`.
///
@Suite("GPIO Tests with gpioget", .serialized)
struct RaspiGPIOHandlerTests {
    
    static var onLinux: Bool {
        #if os(Linux)
        return true
        #else
        return false
        #endif
    }
    
    /// Sets up the GPIO simulator by running the shell command
    /// ```bash
    /// fakegpio init 18 19
    /// ```
    /// 
    /// - Note: Refer to the developer documentation to learn how the GPIO simulator
    /// works in this context: <doc:DevelopmentDocumentation#External-Load-Limiting-through-GPIOs>
    static func initGPIOSimulator() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/fakegpio")
        process.arguments = ["init", "18", "19"]
        
        try? process.run()
        process.waitUntilExit()
    }
    
    /// Shutdown the simulator by running the shell command
    /// ```bash
    /// fakegpio reset
    /// ```
    ///
    /// - Note: Refer to the developer documentation to learn how the GPIO simulator
    /// works in this context: <doc:DevelopmentDocumentation#External-Load-Limiting-through-GPIOs>
    static func deinitGPIOSimulator() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/fakegpio")
        process.arguments = ["reset"]
        
        try? process.run()
        process.waitUntilExit()
    }
    
    /// Ensure GPIO inputs are working correctly
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
    ///
    /// - Note: The `gpioget` simulator gets activated
    /// on macOS only. On linux systems, the native `gpioget`
    /// binary is used.
    @Test("Check for valid state")
    func checkForValidState() throws {
        #if os(macOS)
        Self.initGPIOSimulator()
        defer { Self.deinitGPIOSimulator() }
        #endif
        let gpio18 = RaspiGPIOController(gpiochip: .chip0, pin: 18)
        let state = try gpio18.getPinState()
        #expect(state == .high || state == .low)
    }
    
    /// Ensure unaccessible GPIOs throw
    ///
    /// Make sure `gpioget` is returning an error, e.g.
    /// by resetting the simulator via
    /// ```bash
    /// fakegpio reset
    /// ```
    ///
    /// - Note: This test will most likely only succeed on macOS (and linux systems where no
    /// `gpioget` binary is available or not working correctly). Therefore it will be disabled for linux
    /// systems under the assumption that running on linux always provides a working `gpioget` and
    /// the test then would never succeed.
    /// Anyhow, this step is essential to test, to ensure that errors occuring during reading the GPIO
    /// state are propagated to the main run loop and from there to the cloud. Otherwise this error would
    /// fail silently without anybody recognizing.
    @Test("checkForError", .enabled(if: !Self.onLinux))
    func checkForError() throws {
        Self.deinitGPIOSimulator()
        let gpioloadlimiter = ReComputerDIGPIOLoadLimiter()
        #expect(throws: SystemError.ioErrorToolFailed) {
            try gpioloadlimiter.loadLimitingSignal
        }
    }
}

