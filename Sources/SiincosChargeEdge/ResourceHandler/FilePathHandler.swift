//
//  FilePathHandler.swift
//  SiiSenseAgent
//
//  Created by Johannes Kinzig on 23.02.26.
//

import Foundation


/// A namespace for file path–related utilities.
///
/// `FilePathHandler` provides helper methods for working with file system
/// paths. It is declared as an `enum` with no cases to prevent instantiation
/// and to serve purely as a static namespace for functions.
///
/// Example:
/// ```swift
/// try FilePathHandler().ensureDirectoryExists(forFile: "/tmp/nonexistent/subdir/myfile.txt")
/// ```
enum FilePathHandler {

    /// Returns a writable `FileHandle` for the given file URL, creating the file and its
    /// parent directories if it doesn't exist.
    ///
    /// If a file already exists at `fileURL`, this method opens a handle for writing to it.
    /// If the file does not exist, it creates an empty file at the specified location and then
    /// opens a writable handle. This is useful when you want to ensure a file is available for
    /// writing without having to separately check for existence and create it.
    ///
    /// - Parameter fileURL: The full file URL for which to obtain a writable file handle.
    /// - Returns: A `FileHandle` configured for writing to the file at `fileURL`.
    /// - Throws: An error if opening the file handle for writing fails after ensuring the file exists.
    static func getFileHandle(at fileURL: URL) throws -> FileHandle {
        let fileHandle: FileHandle
        try Self.ensureDirectoryExists(forFile: fileURL)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            fileHandle = try FileHandle(forWritingTo: fileURL)
        } else {
            let _ = FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            fileHandle = try FileHandle(forWritingTo: fileURL)
        }
        return fileHandle
    }

    /// Ensures that the parent directory for a given file path exists.
    ///
    /// If the directory hierarchy for the provided file path does not exist,
    /// this method creates it using `FileManager` with intermediate directories enabled.
    /// This is useful before attempting to create or write a file at `filePath`.
    ///
    /// - Parameter fileURL: The full URL to a file whose parent directory should exist.
    /// - Throws: Rethrows any error produced by `FileManager` when creating the directory,
    ///           such as permission issues or invalid paths.
    /// - Note: This method does not create the file itself; it only ensures that its
    ///         containing directory exists.
    private static func ensureDirectoryExists(forFile fileURL: URL) throws {
        let parentDirectory = fileURL.deletingLastPathComponent()

        if !FileManager.default.fileExists(atPath: parentDirectory.path) {
            try FileManager.default.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
