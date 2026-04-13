//
//  FileResourceLoader.swift
//  SiiSenseAgent
//
//  Created by Johannes Kinzig on 16.09.25.
//

import Foundation
import Logging


/// Load data from file
///
/// Load json data from file by reading its content
/// and transforming it to the desired data type
struct JsonFileResourceLoader {

    let logger: Logger = ComponentSupplier.mainLogger

    init() { }

    /**
     Load data from file

     Load data from file and return its corresponding instance
     - Parameter fromFile: absolute path to file containing the data to load
     - Returns: File content as instance of type specified at call time.
     - Note: Returns nil in case data was not able to be loaded from file
     */
    func load<T: Codable>(fromFile: String) -> T? {
        let decoder = JSONDecoder()
        var textData: Data
        var fileContentInstance: T?
        do {
            textData = try loadTextFromFile(fromFile: fromFile)
            fileContentInstance = try decoder.decode(T.self, from: textData)
        } catch {
            self.logger.error("Error loading product config from file: \(fromFile)", metadata: ["error": "\(error)"])
        }
        return fileContentInstance
    }
    
    // MARK: Private methods

    /**
     Load data from file

     Load data from file and return as `Data`
     - Parameter fromFile: absolute path to file containing the data to load
     - Returns: text as Data
     - Note: Throws in case data was not able to be loaded from file
     */
    private func loadTextFromFile(fromFile: String) throws -> Data {
        let fileUrl = URL(fileURLWithPath: fromFile, isDirectory: false)
        // print("File Path: \(fileUrl)")
        let jsonData = try Data(contentsOf: fileUrl)
        // print("Data (as String): \(String(decoding: jsonData, as: UTF8.self))")
        return jsonData
    }
}
