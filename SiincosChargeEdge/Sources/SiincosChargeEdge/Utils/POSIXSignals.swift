//
//  POSIXSignals.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 07.07.26.
//

import Foundation

enum PosixSignals {

    static let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    static let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)

    @MainActor static var shutdownHandler: (() -> Void)? = nil

    /// Register Shutdown Handler
    ///
    /// Register a function to call when the app receives `SIGINT` or `SIGTERM`
    @MainActor
    static func registerTerminationHandler(run: (() -> Void)? = nil) {
        Self.shutdownHandler = run

        sigintSource.setEventHandler { handle(signal: SIGINT) }
        sigtermSource.setEventHandler { handle(signal: SIGTERM) }

        sigintSource.resume()
        sigtermSource.resume()
    }

    // MARK: Signal handling

    /// Handle received signal
    ///
    /// In this simplified case, disconnect and shut down
    @MainActor
    static func handle(signal: Int32) {
        sigintSource.cancel()
        sigtermSource.cancel()
        Self.shutdownHandler?()
    }

}
