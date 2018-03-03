//
//  FirebaseDatabaseObserver.swift
//  ProjectBeacons
//
// Firebase Database Manager implements observable protocol, it observes changes to particular nodes in firebase
// real time database (RTDB) and notifies observers of the changes
// and saves data into firebase RTDB
//
//  Created by Maria Syed on 18/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import Firebase
import CoreData

class FirebaseDatabaseManager: Observable {
    var ref: DatabaseReference!
    var context: NSManagedObjectContext!
    var firebaseObservers: [Observer] = []
    let storageRef = Storage.storage().reference()
    
    init(context: NSManagedObjectContext) {
        self.ref = Database.database().reference()
        self.context = context
    }
    
    // MARK: - Observable Methods
    
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
        print("notifying observers")
        for observer in firebaseObservers {
            observer.performAction()
        }
    }
    
    // MARK: - Public Methods
    
    public func observeAndSyncData() {
        // start observing data
        _ = ref.child("users").observe(DataEventType.value, with: { (snapshot) in
            let userDict = snapshot.value as? [String : [String: AnyObject]] ?? [:]
            
            print("OBSERVED NEW DATA")
            
            self.syncCoreData(withUsers: Array(userDict.keys))
            
            for (_, info) in userDict {
                if !info.isEmpty {
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
            "timestamp": beaconEvent.timestamp?.convertToISO() ?? "",
            "triggerEvent": beaconEvent.triggerEvent ?? "",
            "major": beaconEvent.major ?? "",
            "minor": beaconEvent.minor ?? "",
            "uuid": (beaconEvent.uuid as UUID?)!.uuidString
        ]
        let newBeaconEventRef = self.ref.child("users/" + name.lowercased() + "/beaconEvents").childByAutoId()
        newBeaconEventRef.setValue(newBeaconEvent)
    }
    
    public func savePerson(withName name: String, withImage imageData: Data?, onCompletion: @escaping () -> Void, onFailure: @escaping () -> Void) {
        self.ref.child("users/").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            if snapshot.hasChild(name.lowercased()) == false {
                self.ref.child("users/" + name.lowercased() + "/name").setValue(name)
            }
        })
        if let data = imageData {
            uploadImageToFirebaseStorage(imageData: data, forName: name, onCompletion: onCompletion, onFailure: onFailure)
        } else {
            onCompletion()
        }
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
    
    public func updateUserPhoto(forName name: String) {
        do {
            let person = try Person.getOrCreatePersonWith(name: name, context: self.context)
            if let p = person {
                DispatchQueue.global().sync {
                    self.downloadImageFromFirebaseStorage(forName: name, onCompletion: { data in
                        DispatchQueue.main.async {
                            p.profilePhoto = data as NSData
                            try? self.context.save()
                            self.notifyObservers()
                        }
                    }, onFailure: {
                        print("Fetching image failed")
                    })
                }
            }
        } catch {
            print("Error updating user photo \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func syncUserWithCoreData(userInfo: [String: AnyObject]) {
        do {
            let person = try Person.getOrCreatePersonWith(name: userInfo["name"] as? String ?? "", context: self.context)
            if let p = person {
                let name = userInfo["name"] as? String ?? ""
                p.name = name
                
                // Downlaod image from storage for the person
                DispatchQueue.global().sync {
                    self.downloadImageFromFirebaseStorage(forName: name, onCompletion: { data in
                        DispatchQueue.main.async {
                            p.profilePhoto = data as NSData
                            try? self.context.save()
                            self.notifyObservers()
                        }
                    }, onFailure: {
                        print("Fetching image failed")
                    })
                }
                
                
                // beacon events from firebase
                let beaconEvents = userInfo["beaconEvents"] as? [String: [String: Any]] ?? [:]
                
                // save each new beacon event for user from Firebase into CoreData
                for (_, beaconEvent) in beaconEvents {
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
        print("users are \(users)")
        let fetchRequest: NSFetchRequest<Person> = Person.fetchRequest()
        let personsInCoreData = try! context.fetch(fetchRequest)
        
        for person in personsInCoreData {
            let i = users.index(where: {$0 == (person.name?.lowercased() ?? "Unknown")})
            if i == nil {
                print("deleting person \(person)")
                context.delete(person)
            }
        }
    }
    
    private func uploadImageToFirebaseStorage(imageData: Data, forName name: String, onCompletion: @escaping () -> Void, onFailure: @escaping () -> Void) {
        let imageRef = storageRef.child(name.lowercased() + "/profileImage.jpg")
        let uploadMetadata = StorageMetadata()
        uploadMetadata.contentType = "image/jpeg"
        let uploadTask = imageRef.putData(imageData, metadata: uploadMetadata) { (metadata, error) in
            if !(metadata != nil) {
                onCompletion()
//                onFailure()
//                print("FATAL ERROR: No metadata found for profile image")
            }
        }
        
        uploadTask.observe(.success) { snapshot in
            onCompletion()
        }
        
        uploadTask.observe(.failure) { snapshot in
            onFailure()
        }
    }
    
    private func downloadImageFromFirebaseStorage(forName name: String, onCompletion: @escaping (_ data: Data) -> Void, onFailure: @escaping () -> Void) {
        let imageRef = storageRef.child(name.lowercased() + "/profileImage.jpg")
        imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error fetching profile image \(error)")
                onFailure()
            } else {
                // Set new photo
                if let data = data {
                    onCompletion(data)
                }
            }
        }
    }
//
//    struct P {
//        var ref: NSManagedObjectID! = nil
//        let name: String
//    }
    
}





