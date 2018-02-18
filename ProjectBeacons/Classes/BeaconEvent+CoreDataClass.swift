//
//  BeaconEvent+CoreDataClass.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 18/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
//

import Foundation
import CoreData

@objc(BeaconEvent)
public class BeaconEvent: NSManagedObject {

    class func createUniqueBeaconEvent(withPerson person: Person?, withLocationID locationID: String?, withTimestamp timestamp: Date?, context: NSManagedObjectContext) throws -> BeaconEvent? {
        
        // Need to check matching locationID, timestamp and person before creating new beacon event
        // ie. if same person visits same location at exactly the same time then do not create new beacon event
        if let locationID = locationID, let timestamp = timestamp, let person = person {
            let request: NSFetchRequest<BeaconEvent> = BeaconEvent.fetchRequest()
            
            // match with location id and timestamp
            request.predicate = NSPredicate(format: "locationID =[cd] %@ && timestamp == %@ && person == %@", locationID, timestamp as NSDate, person)
            
            do {
                let matchingBeaconEvents = try context.fetch(request)
                if matchingBeaconEvents.count == 0 {
                    let newBeaconEvent = BeaconEvent(context: context)
                    return newBeaconEvent
                } else {
                    return nil
                }
            } catch {
                throw error
            }
        } else {
            return nil
        }
    }
}
