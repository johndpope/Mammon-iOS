//
//  Utils.swift
//  Mammon
//
//  Created by Simon Shoban on 2019-01-18.
//  Copyright © 2019 Simon Shoban. All rights reserved.
//

import Foundation

class Utils {
    class func getCurrentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        
        // January 1st, 2019 -> 2019/01/01; December 31st, 2019 -> 2019/12/31
        formatter.dateFormat = "yyyy/MM/dd"
        
        return formatter.string(from: date)
    }
    
    class func convertStringDateFormat(dateString: String, oldFormat: String, newFormat: String) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = oldFormat
        
        let date = formatter.date(from: dateString)
        
        formatter.dateFormat = newFormat
        
        return formatter.string(from: date!)
    }
    
    class func getHumanizedDateString(dateString: String) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy/MM/dd"
        
        let date = formatter.date(from: dateString)
        
        formatter.dateStyle = .medium
        
        return formatter.string(from: date!)
    }
    
    class func getPlist(_ name: String) -> NSDictionary? {
        if let path = Bundle.main.path(forResource: name, ofType: "plist") {
            return NSDictionary(contentsOfFile: path)
        }
        
        return nil
    }
    
    class func getAppConfigProperty(category: String, key: String) -> String {
        return (getPlist("appconfig")!.object(forKey: category)! as AnyObject).object(forKey: key) as! String
    }
}
