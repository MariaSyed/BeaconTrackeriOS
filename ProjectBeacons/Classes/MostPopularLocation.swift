//
//  Location.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 17/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import Foundation

class MostPopularLocation {
    var locationName: String?
    var numberOfVisits: Int?
    var timeSinceLastVisit: Int?
    var locationID: String?
    
    init(locationID: String, locationName: String, numberOfVisits: Int, timeSinceLastVisit: Int) {
        self.locationID = locationID
        self.locationName = locationName
        self.numberOfVisits = numberOfVisits
        self.timeSinceLastVisit = timeSinceLastVisit
    }
}