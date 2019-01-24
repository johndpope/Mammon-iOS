//
//  DirectoryManager.swift
//  Mammon
//
//  Created by Simon Shoban on 2019-01-11.
//  Copyright © 2019 Simon Shoban. All rights reserved.
//

import Foundation

class DirectoryManager {
    private static let DATABASE_NAME: String = Utils.getAppConfigProperty(category: "local", key: "local_db_name")
    private static let DATABASE_PATH: String = Utils.getAppConfigProperty(category: "local", key: "local_db_path")
    
    class func getFileTimestamp(path: String) throws -> Date? {
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        
        return attr[FileAttributeKey.modificationDate] as? Date
    }
    
    class func getFilePath(path: String) -> String {
        let tDocumentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        return tDocumentDirectory!.appendingPathComponent(path).path
    }
    
    class func createDatabaseDirectoryIfNotExists() {
        let databaseFilePath = getFilePath(path: DATABASE_PATH)
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: databaseFilePath) {
            do {
                try fileManager.createDirectory(atPath: databaseFilePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create document directory")
            }
        }
    }
    
    class func getDatabaseLocation() -> String {
        return getFilePath(path: DATABASE_PATH + DATABASE_NAME)
    }
    
    class func localDatabaseExists() -> Bool {
        if FileManager.default.fileExists(atPath: getDatabaseLocation()) {
            print("Database exists!")
            return true
        }
        
        return false
    }
}
