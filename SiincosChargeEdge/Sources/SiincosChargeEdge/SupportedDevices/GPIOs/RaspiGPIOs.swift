//
//  RaspiGPIOs.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 14.10.26.
//

import Foundation
import Logging

enum GpioChip: String, RawRepresentable {
    case chip0 = "gpiochip0"
}

/// Provide access to the system's digital inputs through the native GPIOs
/// using the `gpioget` binary available on most single board computers.
///
/// `gpioget` is called as follows: `gpioget -c <gpiochipX> -l --numeric <pin>`, e.g.:
/// `gpioget -c gpiochip0 -l --numeric 18`. The `-l` option makes `gpioget`
/// to report a low pin as active (1) and vice-versa.
///
/// Refer to <doc:DevelopmentDocumentation#External-Load-Limiting-through-GPIOs>
/// for more details and usage on systems where native GPIOs are not available.
struct RaspiGPIOController: GpioController {
    let binExecPath: String
    let arguments: [String]
    private let logger = ComponentSupplier.mainLogger

    /// Init pin reading.
    ///
    /// - Parameters:
    ///   - gpiochip: which gpiochip to use, defaults: `gpiochip8`
    ///   - pin: the pin number to read
    init(gpiochip: GpioChip = .chip0, pin: UInt8) {
        self.arguments = [ "-c", gpiochip.rawValue, "-l", "--numeric", String(pin) ]
        self.binExecPath = {
           #if os(Linux)
               return "/usr/bin/gpioget"
           #else
               return "/usr/local/bin/gpioget"
           #endif
       }()
        
    }
    
    /// Read GPIO pin
    ///
    /// Reads the pin state through `gpioget` command with the `-l` (active-low) option,
    /// making `gpioget` to report a low pin as active (1) and vice-versa.
    ///
    /// - Returns: the pin state as ``PinState/high`` or ``PinState/low``.
    func getPinState() throws -> PinState {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binExecPath)
        proc.arguments = arguments
        let stdOut = Pipe()
        proc.standardOutput = stdOut
        try proc.run()
        let data = stdOut.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        
        guard proc.terminationStatus == 0 else {
            self.logger.error("\(SystemError.ioErrorToolFailed.localizedDescription), error code: \(proc.terminationStatus)")
            throw SystemError.ioErrorToolFailed
        }
        
        let response = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let value = Int(response) else {
            self.logger.error("\(SystemError.ioErrorUnexpectedToolResponse.localizedDescription), response: \(response)")
            throw SystemError.ioErrorUnexpectedToolResponse
        }
        return value == 1 ? .high : .low
    }
}
