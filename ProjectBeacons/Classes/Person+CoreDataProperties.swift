//
//  Person+CoreDataProperties.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 17/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
//

import Foundation
import CoreData


extension Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person")
    }

    @NSManaged public var name: String?
    @NSManaged public var profilePhoto: NSData?
    @NSManaged public var userId: Int64
    @NSManaged public var beaconEvents: NSSet?

}

// MARK: Generated accessors for beaconEvents
extension Person {

    @objc(addBeaconEventsObject:)
    @NSManaged public func addToBeaconEvents(_ value: BeaconEvent)

    @objc(removeBeaconEventsObject:)
    @NSManaged public func removeFromBeaconEvents(_ value: BeaconEvent)

    @objc(addBeaconEvents:)
    @NSManaged public func addToBeaconEvents(_ values: NSSet)

    @objc(removeBeaconEvents:)
    @NSManaged public func removeFromBeaconEvents(_ values: NSSet)

}
