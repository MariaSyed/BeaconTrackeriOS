//
//  Location.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 17/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import Foundation

class Location {
    var locationName: String?
    var numberOfVisits: Int?
    var timeSinceLastVisit: Int?
    
    init(locationName: String, numberOfVisits: Int, timeSinceLastVisit: Int) {
        self.locationName = locationName
        self.numberOfVisits = numberOfVisits
        self.timeSinceLastVisit = timeSinceLastVisit
    }
}
