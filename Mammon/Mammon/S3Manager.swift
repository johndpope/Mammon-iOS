//
//  S3Manager.swift
//  Mammon
//
//  Created by Simon Shoban on 2019-01-11.
//  Copyright © 2019 Simon Shoban. All rights reserved.
//

import Foundation
import AWSS3

class S3Manager {
    private static let S3_BUCKET_NAME: String = Utils.getAppConfigProperty(category: "aws", key: "aws_s3_db_backup_bucket")
    private static let S3_DATABASE_KEY: String = Utils.getAppConfigProperty(category: "aws", key: "aws_s3_db_key")
    private static let LOCAL_DB_LOCATION: String = DirectoryManager.getDatabaseLocation()
    
    class func loadDatabaseFromS3() {
        let downloadRequest = getDownloadRequest()
        let transferManager = AWSS3TransferManager.default()
        
        transferManager.download(downloadRequest!).continueWith {
            (task: AWSTask!) -> AnyObject? in
            if task.error != nil {
                print("Error downloading")
                print(task.error.debugDescription)
            }
            else {
                print(LOCAL_DB_LOCATION)
            }
            
            return nil
        }
    }
    
    class func uploadDatabaseToS3() {
        let uploadRequest = getUploadRequest()
        let transferManager = AWSS3TransferManager.default()
        
        transferManager.upload(uploadRequest!).continueWith {
            (task: AWSTask!) -> AnyObject? in
            if task.error != nil {
                print("Error uploading")
                print(task.error.debugDescription)
                // Alert user of failed upload
            }
            
            return nil
        }
    }
    
    private class func getUploadRequest() -> AWSS3TransferManagerUploadRequest? {
        let uploadingFileURL = URL(fileURLWithPath: LOCAL_DB_LOCATION)
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        uploadRequest!.bucket = S3_BUCKET_NAME
        uploadRequest!.key = S3_DATABASE_KEY
        uploadRequest!.body = uploadingFileURL
        uploadRequest!.contentType = "application/x-sqlite3"
        
        return uploadRequest
    }
    
    class private func getDownloadRequest() -> AWSS3TransferManagerDownloadRequest? {
        let downloadingFileURL = URL(fileURLWithPath: LOCAL_DB_LOCATION)
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest!.bucket = S3_BUCKET_NAME
        downloadRequest!.key = S3_DATABASE_KEY //fileName on s3
        downloadRequest!.downloadingFileURL = downloadingFileURL
        
        return downloadRequest
    }
    
    class func newerDatabaseIsAvailable() -> Bool {
        let s3Timestamp = getS3Timestamp()
        
        print("Checking metadata")
        
        // If there was an error getting the timestamp from S3, keep local database
        if (s3Timestamp == nil) {
            print("nil timestamp")
            return false
        }
        
        do {
            let localDbTimestamp = try DirectoryManager.getFileTimestamp(path: LOCAL_DB_LOCATION)
            
            return s3Timestamp! > localDbTimestamp!
        } catch {
            // If there was an error getting the timestamp from the local database, keep the local database
            return false
        }
    }
    
    class private func getS3Timestamp() -> Date? {
        let request = AWSS3HeadObjectRequest()
        let s3 = AWSS3.default()
        let semaphore = DispatchSemaphore(value: 0)
        
        var timestamp: Date? = nil
        
        request!.bucket = S3_BUCKET_NAME
        request!.key = S3_DATABASE_KEY
        
        // Use global queue to perform this task in the background
        DispatchQueue.global().async {
            s3.headObject(request!) {
                (output : AWSS3HeadObjectOutput?, error : Error?) -> Void in
                
                if error != nil {
                    print("Error: could not find file \(error!)")
                } else {
                    print("Got metadata")
                    timestamp = output?.lastModified!
                }
                
                semaphore.signal()
            }
        }
        
        // Block until semaphore signals that the file metadata has been read from S3
        semaphore.wait()
        
        return timestamp
    }
}
