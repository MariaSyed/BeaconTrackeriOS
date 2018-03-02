//
//  LastLocationsTableViewController.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 06/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationsTableViewController: UITableViewController, CLLocationManagerDelegate, Observer {
    typealias Controller = NSFetchedResultsController<Person>
    
    var firebaseManager: FirebaseDatabaseManager!
    var username: String?
    var newPhotoSet: Bool = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let beaconManager = BeaconManager(proximityUUID: UUID(uuidString: "9CFEC685-0722-228D-2189-CFAE06FBE1B5")!, identifier: "Olohuone")
    
    lazy var dataSource = LocationsTableViewDataSource(context: context, matchingName: username ?? "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.topItem?.title = "Back"
        
        // TableView
        tableView.rowHeight = 80
        tableView.dataSource = dataSource as UITableViewDataSource
        
        dataSource.refetchFRC()
        
        // Firebase
        firebaseManager.registerObserver(observer: self)

        if let name = username, newPhotoSet == true {
            firebaseManager.updateUserPhoto(forName: name)
        }
        
        // Beacons
        beaconManager.locationManager.delegate = self
        beaconManager.startMonitoring()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IBActions
    
    @IBAction func onSwitchAccount(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Observer Methods
    
    func performAction() {
        dataSource.refetchFRC()
        tableView.endUpdates()
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? LocationsTableViewCell else {
            fatalError("cell to be displayed is not a LocationsTableViewCell")
        }
        
        let person = dataSource.getPerson(atIndexPath: indexPath)
        
        // Configure cell
        
        // Set subtitle with most recent location name and minutes elapsed
        if let beaconEventsSet = person.beaconEvents {
            // convert set to array
            let beaconEventsArray: [BeaconEvent] = Array(beaconEventsSet) as! [BeaconEvent]
            if (beaconEventsArray.count > 0) {
                
                let mostRecentBeaconEvent : BeaconEvent = beaconEventsArray.reduce(beaconEventsArray[0], { $0.timestamp!.timeIntervalSince1970 > $1.timestamp!.timeIntervalSince1970 ? $0 : $1 } )
                
                
                if let locationName = mostRecentBeaconEvent.locationName {
                    cell.locationLabel?.text = locationName
                }
                
                if let timestamp = mostRecentBeaconEvent.timestamp {
                    let secondsPassed = timestamp.timeIntervalSinceNow
                    
                    let minutesPassed = Int(abs(secondsPassed) / 60)
                    
                    cell.timeLabel?.text? = "\(minutesPassed) min ago"
                    
                }
            }
        }
        
        let defaultPhoto = UIImageJPEGRepresentation(UIImage(named: "userImage")!, 0.8)! as NSData
        
        cell.titleLabel?.text = person.name
        cell.profileImage.image = UIImage(data: (person.profilePhoto ?? defaultPhoto) as Data)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let person = dataSource.getPerson(atIndexPath: indexPath)
        
        let historyVC = self.storyboard?.instantiateViewController(withIdentifier: "LocationHistoryTableViewController") as! LocationHistoryTableViewController
        
        if let beaconEventsSet = person.beaconEvents  {
            let beaconEventsArray = Array(beaconEventsSet) as! [BeaconEvent]
            historyVC.beaconEvents = beaconEventsArray
            let navController = UINavigationController(rootViewController: historyVC)
            self.present(navController, animated: true)
        }
        
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("started monitoring for \(region)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    // TODO: Remove this ranging func later, placed here for testing
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("\(username ?? "Unknown User") did range \(beacons)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let beaconEvent: BeaconEvent = createBeaconEvent(withRegion: region as! CLBeaconRegion, triggerEvent: "enter")
        firebaseManager.saveBeaconEvent(beaconEvent: beaconEvent, forName: username ?? "Unknown")
        print("\(username ?? "Unknown User") just entered region \(region)")
    }
   
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let beaconEvent: BeaconEvent = createBeaconEvent(withRegion: region as! CLBeaconRegion, triggerEvent: "exit")
        firebaseManager.saveBeaconEvent(beaconEvent: beaconEvent, forName: username ?? "Unknown")
        print("\(username ?? "Unknown User") just exitted region \(region)")
    }
    
    func createBeaconEvent(withRegion region: CLBeaconRegion, triggerEvent: String) -> BeaconEvent {
        // Get major, minor, uuid from region
        let uuid = region.proximityUUID
        let major = region.major ?? 0
        let minor = region.minor ?? 0

        // Create locationID from major minor values
        let locationID = "\(major)-\(minor)"
        let locationName = firebaseManager.getLocationName(fromLocationID: locationID)
        
        // Get timestamp from Date(), username, trigger = triggerEvent
        let timestamp = Date()
        let triggerEvent = "exit"
        
        // Create & return BeaconEvent from the above data
        let beaconEvent = BeaconEvent(context: context)
        
        beaconEvent.uuid = uuid
        beaconEvent.locationID = locationID
        beaconEvent.locationName = locationName
        beaconEvent.major = "\(major)"
        beaconEvent.minor = "\(minor)"
        beaconEvent.timestamp = timestamp as NSDate
        beaconEvent.triggerEvent = triggerEvent
        
        return beaconEvent
    }
}
