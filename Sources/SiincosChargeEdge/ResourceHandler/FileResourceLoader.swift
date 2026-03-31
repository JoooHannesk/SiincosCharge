//
//  FileResourceLoader.swift
//  SiiSenseAgent
//
//  Created by Johannes Kinzig on 16.09.25.
//

import Foundation
import Logging


struct FileResourceLoader {
    
    let searchPath: String
    let logger: Logger?

    init(searchPath: String, logger: Logger?) {
        self.searchPath = searchPath
        self.logger = logger
    }

    /**
     Load data from file

     Load data from file and return its corresponding instance
     - Parameter fromFile: file name (as files in resource location) containing data
     - Returns: Instance of type defined in the provided file. `nil` in case file parsing failed.
     - Note: Returns nil in case data was not able to be loaded from file
     */
    func load<T: Codable>(fromFile: String) -> T? {
        let decoder = JSONDecoder()
        var textData: Data
        var fileContentInstance: T?
        do {
            textData = try loadTextFromFile(fileName: fromFile)
            fileContentInstance = try decoder.decode(T.self, from: textData)
        } catch {
            self.logger?.error("Error loading product config from file: \(fromFile)", metadata: ["error": "\(error)"])
        }
        return fileContentInstance
    }
    
    // MARK: Private methods
    
    /**
     Return path to requested test resource, where the resource is a json file
     - Parameter fileName: file name for test resource
     - Returns: URL to test resource
     */
    private func getPathToResource(fileName: String) -> URL {
        let fileName = fileName
        let urlToThisFile = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
        return urlToThisFile.appendingPathComponent(searchPath).appendingPathComponent(fileName)
    }
    
    /**
     Load text from file
     - Parameter fileName: file name (must be present in the location provided under `searchPath`)
     - Returns: text as Data?
     - Note: Throws in case data was not able to be loaded from file
     */
    private func loadTextFromFile(fileName: String) throws -> Data {
        let fileUrl = getPathToResource(fileName: fileName)
        print("File Path: \(fileUrl)")
        let jsonData = try Data(contentsOf: fileUrl)
        // print("Mock data: \(String(decoding: jsonData, as: UTF8.self))")
        return jsonData
    }
}
