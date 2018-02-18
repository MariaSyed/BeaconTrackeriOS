//
//  BeaconEvent+CoreDataProperties.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 18/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
//

import Foundation
import CoreData


extension BeaconEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BeaconEvent> {
        return NSFetchRequest<BeaconEvent>(entityName: "BeaconEvent")
    }

    @NSManaged public var locationID: String?
    @NSManaged public var locationName: String?
    @NSManaged public var major: String?
    @NSManaged public var minor: String?
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var triggerEvent: String?
    @NSManaged public var uuid: UUID?
    @NSManaged public var person: Person?

}
