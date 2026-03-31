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
     Load user credentials from file
     - Parameter fileName: file name (as files in resource location) containing data
     - Returns: ServerSettings object
     - Note: Returns nil in case data was not able to be loaded from file
     */
    func loadDeviceConfigFromFile(fileName: String) -> SystemConfig? {
        let decoder = JSONDecoder()
        if let textData = loadTextFromFile(fileName: fileName) {
            let userCredentials = try? decoder.decode(SystemConfig.self, from: textData)
            return userCredentials
        }
        self.logger?.error("Error loading product config from file: \(fileName)")
        return nil
    }
    
    // MARK: Private methods
    
    /**
     Return path to requested test resource, where the resource is a json file
     - Parameter fileName: file name for test resource
     - Returns: URL to test resource
     */
    private func getPathToResource(fileName: String) -> URL {
        let fileName = fileName
        let urlToThisFile = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent()
        return urlToThisFile.appendingPathComponent(searchPath).appendingPathComponent(fileName)
    }
    
    /**
     Load text from file
     - Parameter fileName: file name (as files in resource location) containing data
     - Returns: text as Data?
     - Note: Returns nil in case data was not able to be loaded from file
     */
    private func loadTextFromFile(fileName: String) -> Data? {
        let fileUrl = getPathToResource(fileName: fileName)
        // print("File Path: \(fileUrl)")
        if let jsonData = try? Data(contentsOf: fileUrl) {
            // print("Mock data: \(String(decoding: jsonData, as: UTF8.self))")
            return jsonData
            }
        else {
            self.logger?.error("Error loading file: \(fileName).json")
            return nil
        }
    }
}
