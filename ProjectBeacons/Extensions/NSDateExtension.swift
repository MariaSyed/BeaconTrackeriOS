//
//  NSDateExtension.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 03/03/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import Foundation

extension NSDate {
    func convertToISO() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.string(from: self as Date)
    }
    
    func convertToFormat(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self as Date)
    }
}
