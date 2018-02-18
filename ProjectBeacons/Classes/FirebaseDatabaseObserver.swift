//
//  FirebaseDatabaseObserver.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 18/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import Firebase
import CoreData

class FirebaseDatabaseObserver {
    var ref: DatabaseReference!
    var context: NSManagedObjectContext!
    
    init(context: NSManagedObjectContext) {
        self.ref = Database.database().reference()
        self.context = context
    }
    
    // MARK: - Public Methods
    
    public func observeAndSyncData() {
        // start observing data
        _ = ref.child("users").observe(DataEventType.value, with: { (snapshot) in
            print("triggered firebase observer! Have snapshot now...")
            let userDict = snapshot.value as? [String : [String: AnyObject]] ?? [:]
            
            for (_, info) in userDict {
                self.syncUserWithCoreData(userInfo: info)
            }
            
            do {
                try self.context.save()
            } catch {
                print("Error saving context: \(error)")
            }
            
        })
    }
    
    public func saveBeaconEvent(beaconEvent: BeaconEvent, forName name: String) {
        let newBeaconEvent : [String: Any] = [
            "locationID": beaconEvent.locationID ?? "",
            "locationName": beaconEvent.locationName ?? "",
            "timestamp": beaconEvent.timestamp ?? "",
            "triggerEvent": beaconEvent.triggerEvent ?? "",
            "major": beaconEvent.major ?? "",
            "minor": beaconEvent.minor ?? "",
            "uuid": beaconEvent.uuid ?? ""
        ]
        let newBeaconEventRef = self.ref.child("users/" + name.lowercased() + "/beaconEvents").childByAutoId()
        newBeaconEventRef.setValue(newBeaconEvent)
    }
    
    public func savePerson(withName name: String) {
        // TODO: upload image to Firebase Cloud Storage too
        self.ref.child("users/" + name.lowercased() + "/name").setValue(name)
    }
    
    
    // MARK: - Helper functions
    
    func syncUserWithCoreData(userInfo: [String: AnyObject]) {
        print("syncing beacon events with core data...")
        let person: Person??
        person = try? Person.getOrCreatePersonWith(name: userInfo["name"] as? String ?? "", context: self.context)
        
        if let p = person, let personUnwrapped = p {
            print("Person is: \(personUnwrapped)")
            personUnwrapped.name = userInfo["name"] as? String ?? ""
            // TODO: Need to get actual image from Firebase Cloud
            // Set new photo
            if let image = UIImage(named: "userImage") {
                personUnwrapped.profilePhoto = UIImagePNGRepresentation(image)! as NSData
            }
        }
        
        // beacon events from firebase
        let beaconEvents = userInfo["beaconEvents"] as? [[String: String]] ?? []
        
        // save each new beacon event for user from Firebase into CoreData
        for beaconEvent in beaconEvents {
            let locationID = beaconEvent["locationID"]
            var timestamp: Date?
            
            // convert timestamp in ISO Format to Date
            if let isoStr = beaconEvent["timestamp"] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                timestamp = dateFormatter.date(from: isoStr)
            }
            
            do {
                if let p = person, let personUnwrapped = p {
                    if let newBeaconEvent = try BeaconEvent.createUniqueBeaconEvent(withPerson: personUnwrapped, withLocationID: locationID, withTimestamp: timestamp, context: self.context) {
                        
                        // configure new beacon event with data from firebase
                        newBeaconEvent.locationID = beaconEvent["locationID"] ?? ""
                        newBeaconEvent.timestamp = timestamp as NSDate?
                        newBeaconEvent.locationName = beaconEvent["locationName"] ?? ""
                        newBeaconEvent.major = beaconEvent["major"] ?? ""
                        newBeaconEvent.minor = beaconEvent["minor"] ?? ""
                        newBeaconEvent.triggerEvent = beaconEvent["triggerEvent"] ?? ""
                        
                        print("CREATED NEW UNIQUE BEACON EVENT: \(newBeaconEvent)")

                        // add new beacon event to existing person or new person
                        personUnwrapped.addToBeaconEvents(newBeaconEvent)
                    }
                }
            } catch {
                print("Error creating new beacon event or person: \(error)")
            }
        }
    }
    
}
