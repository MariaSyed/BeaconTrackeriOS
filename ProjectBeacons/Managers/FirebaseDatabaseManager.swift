//
//  FirebaseDatabaseObserver.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 18/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
// Description:
// Firebase Database Manager implements observable protocol, it observes changes to particular nodes in firebase
// real time database (RTDB) and notifies observers of the changes
// and saves data into firebase RTDB

import Firebase
import CoreData

class FirebaseDatabaseManager: Observable {
    func registerObserver(observer: Observer) {
        if firebaseObservers.index(where: {($0 as AnyObject) === (observer as AnyObject)}) == nil {
            firebaseObservers.append(observer)
        }
    }
    
    func deregisterObserver(observer: Observer) {
        if let index = firebaseObservers.index(where: {($0 as AnyObject) === (observer as AnyObject)}) {
            firebaseObservers.remove(at: index)
        }
    }
    
    func notifyObservers() {
        for observer in firebaseObservers {
            observer.performAction()
        }
    }
    
    var ref: DatabaseReference!
    var context: NSManagedObjectContext!
    var firebaseObservers: [Observer] = []
    
    init(context: NSManagedObjectContext) {
        self.ref = Database.database().reference()
        self.context = context
    }
    
    // MARK: - Public Methods
    
    public func observeAndSyncData() {
        // start observing data
        _ = ref.child("users").observe(DataEventType.value, with: { (snapshot) in
            let userDict = snapshot.value as? [String : [String: AnyObject]] ?? [:]
            
            self.syncCoreData(withUsers: Array(userDict.keys))
            
            for (_, info) in userDict {
                if info.isEmpty == false {
                    self.syncUserWithCoreData(userInfo: info)
                    
                } else {
                    print("WARNING: no info found")
                }
            }
            
            do {
                // Let observers know that synchronization is complete
                self.notifyObservers()
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
        savePerson(withName: name)
        let newBeaconEventRef = self.ref.child("users/" + name.lowercased() + "/beaconEvents").childByAutoId()
        newBeaconEventRef.setValue(newBeaconEvent)
    }
    
    public func savePerson(withName name: String) {
        // TODO: upload image to Firebase Cloud Storage too
        self.ref.child("users/").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            if snapshot.hasChild(name.lowercased()) == false {
                self.ref.child("users/" + name.lowercased() + "/name").setValue(name)
            }
        })
    }
    
    public func getLocationName(fromLocationID locationID: String) -> String {
        
        switch (locationID) {
        case "0-1":
            return "Metropolia B112"
        case "0-2":
            return "Metropolia B102"
        case "1-1":
            return "Metropolia A11"
        default:
            return "Unknown Location"
        }
//        var locationDict: [String:  String]?
//
//        _ = ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
//            locationDict = snapshot.value as? [String : String] ?? [:]
//        })
//        if let map = locationDict {
//            if let locationName = map[locationID] {
//                return locationName
//            } else {
//                return "Unknown Location"
//            }
//        } else {
//            return "Unknown Location"
//        }
    }
    
    // MARK: - Private Methods
   
    private func syncUserWithCoreData(userInfo: [String: AnyObject]) {
        do {
            let person = try Person.getOrCreatePersonWith(name: userInfo["name"] as? String ?? "", context: self.context)
            if let p = person {
                p.name = userInfo["name"] as? String ?? ""
                // TODO: Need to get actual image from Firebase Cloud
                // Set new photo
                if let image = UIImage(named: "userImage") {
                    p.profilePhoto = UIImagePNGRepresentation(image)! as NSData
                }
                
                // beacon events from firebase
                let beaconEvents = userInfo["beaconEvents"] as? [[String: Any]] ?? []
                
                // save each new beacon event for user from Firebase into CoreData
                for beaconEvent in beaconEvents {
                    let locationID = beaconEvent["locationID"] as? String
                    var timestamp: Date?
                    
                    if let isoStr = beaconEvent["timestamp"] as? String {
                        timestamp = convertToDate(fromISO: isoStr)
                    }
                    if let p = person {
                        if let newBeaconEvent = try BeaconEvent.createUniqueBeaconEvent(withPerson: p, withLocationID: locationID, withTimestamp: timestamp, context: self.context) {
                            
                            // configure new beacon event with data from firebase
                            newBeaconEvent.locationID = beaconEvent["locationID"] as? String ?? ""
                            newBeaconEvent.timestamp = timestamp as NSDate?
                            newBeaconEvent.locationName = beaconEvent["locationName"] as? String
                            newBeaconEvent.major = beaconEvent["major"] as? String
                            newBeaconEvent.minor = beaconEvent["major"] as? String
                            newBeaconEvent.triggerEvent = beaconEvent["triggerEvent"] as? String
                            
                            // add new beacon event to existing person or new person
                            p.addToBeaconEvents(newBeaconEvent)
                        }
                    }
                }
            }
        } catch {
            print("Error creating person or beacon event \(error)")
        }
    }
    
    private func convertToDate(fromISO iso: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.date(from: iso)
    }
    
    private func syncCoreData(withUsers users: Array<String>) {
        // Remove old data from core data

        let fetchRequest: NSFetchRequest<Person> = Person.fetchRequest()
        let personsInCoreData = try! context.fetch(fetchRequest)
        
        for person in personsInCoreData {
            let i = users.index(where: {$0 == (person.name ?? "Unknown")})
            if i == nil {
                context.delete(person)
            }
        }
    }
    
}
