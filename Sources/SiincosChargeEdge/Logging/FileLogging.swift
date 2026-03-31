//
//  FileLogging.swift
//  SiiSenseAgent
//
//  Created by Johannes Kinzig on 23.02.26.
//

import Logging
import Foundation


/// App Logging
///
/// App-wide logging labels
enum AppLogging {

    fileprivate static let fileLogger = FileLoggingConfiguration()

    /// Get a logger instance for the specified label
    private static func getLogger(for label: String) throws -> Logger {
        return Logger(label: label)
    }

    /// Get logger instances for each logging type
    static let mainLogger = try? getLogger(for: "SiincosChargeEdge")
    static let testsLogger = try? getLogger(for: "TestSuites")

    /// Teardown logger
    static func teardown() async {
        await Self.fileLogger.close()
    }
}


// MARK: Logging backend - private


/// Provide a file handler for the logging system
private struct FileLogHandler: LogHandler {
    private let fileHandle: FileHandle
    private let label: String
    public var metadata: Logger.Metadata = [:]
    public var logLevel: Logger.Level = .info

    init(label: String, fileHandle: FileHandle) {
        self.label = label
        self.fileHandle = fileHandle
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        var combinedMetadata = self.metadata
        if let metadata = metadata {
            combinedMetadata.merge(metadata) { _, new in new }
        }

        let metaString = combinedMetadata.isEmpty ? "" : " \(combinedMetadata)"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())

        let line = "\(timestamp) [\(level)] \(label): \(message)\(metaString)\n"
        if let data = line.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            // Use a simple write; ignore errors to avoid crashing logging
            try? fileHandle.write(contentsOf: data)
        }
    }
}

/// File Logging Configuration
///
/// File logging configuration for the project specific global logger (based on swift-log)
fileprivate actor FileLoggingConfiguration {

    static let logFileBasePath = AppConstants.logFolderLocation
    let fileHandle: FileHandle!

    /// Generate log file name
    ///
    /// Each log file takes the current date, with the following format
    /// "yyyy-MM-dd", e.g. 2026-05-31.log
    static private func generateLogFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "\(dateString).log"
    }

    /// Setup the Logging system
    ///
    /// Set up the logging system, by passing the `FileLogHandler`
    init() {
        let logFileName = "\(Self.logFileBasePath)\(Self.generateLogFileName())"
        let logFileURL = URL(fileURLWithPath: logFileName)

        do {
            self.fileHandle = try FilePathHandler.getFileHandle(at: logFileURL)
        } catch {
            fatalError("Unable to open file for logging: \(error)")
        }

        LoggingSystem.bootstrap { label in
            return FileLogHandler(label: label, fileHandle: self.fileHandle)
        }
    }

    /// Close the file logger
    ///
    /// Synchronize and close the file handle safely
    /// - Note: Call this immediately before quitting the application.
    /// An earlier call will result in a broken logger.
    func close() {
        try? self.fileHandle.synchronize()
        try? self.fileHandle.close()
    }
}
