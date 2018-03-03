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
    let beaconManager = BeaconManager()
    let regions = [
        CLBeaconRegion(proximityUUID: UUID(uuidString: "00001111-2222-3333-4444-555566667777")!, major: 0, minor: 1, identifier: "OLD2"),
        CLBeaconRegion(proximityUUID: UUID(uuidString: "00001111-2222-3333-4444-555566667777")!, major: 0, minor: 2, identifier: "OLD2"),
        CLBeaconRegion(proximityUUID: UUID(uuidString: "00001111-2222-3333-4444-555566667777")!, major: 1, minor: 0, identifier: "OLD2")
    ]
    
    var scanning: Bool = false
    @IBOutlet weak var scanButton: UIBarButtonItem!

    lazy var dataSource = LocationsTableViewDataSource(context: context, matchingName: username ?? "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TableView
        tableView.rowHeight = 80
        tableView.dataSource = dataSource as UITableViewDataSource
        
        dataSource.performFetch()
        
        // Firebase
        firebaseManager.registerObserver(observer: self)

        if let name = username, newPhotoSet == true {
            firebaseManager.updateUserPhoto(forName: name)
        }
        
        // Beacons
        beaconManager.locationManager.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IBActions
    
    @IBAction func onSwitchAccount(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onToggleScan(_ sender: UIBarButtonItem) {
        scanning = !scanning
        if scanning == true {
            beaconManager.startMonitoring(forRegions: regions)
            scanButton.title = "Stop Scan"
        } else {
            beaconManager.stopMonitoring(forRegions: regions)
            scanButton.title = "Start Scan"
        }
    }
    
    // MARK: - Observer Methods
    
    func performAction() {
        tableView.beginUpdates()
        dataSource.performFetch()
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
                    
                    let minutesPassed = Int(secondsPassed / 60).magnitude
                    
                    if minutesPassed > 90 {
                        cell.timeLabel.text = "at \(timestamp)"
                    } else {
                        cell.timeLabel.text = "\(minutesPassed) min ago"
                    }
                    
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
            navController.navigationBar.topItem?.title = "\(person.name ?? "User")'s Locations"
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
        
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("\(username ?? "Unknown User") just entered region \(region)")
        let beaconEvent: BeaconEvent = createBeaconEvent(withRegion: region as! CLBeaconRegion, triggerEvent: "Enter")
        print("created beacon event: \(beaconEvent)")
        firebaseManager.saveBeaconEvent(beaconEvent: beaconEvent, forName: username ?? "Unknown")
    }
   
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("\(username ?? "Unknown User") just exitted region \(region)")
        let beaconEvent: BeaconEvent = createBeaconEvent(withRegion: region as! CLBeaconRegion, triggerEvent: "Exit")
        firebaseManager.saveBeaconEvent(beaconEvent: beaconEvent, forName: username ?? "Unknown")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("Got state \(state.rawValue) for region \(region)")
    }
    
    func createBeaconEvent(withRegion region: CLBeaconRegion, triggerEvent: String) -> BeaconEvent {
        print("creating BE from region: \(region)")
        // Get major, minor, uuid from region
        let uuid = region.proximityUUID
        let major = region.major ?? 0
        let minor = region.minor ?? 0

        // Create locationID from major minor values
        let locationID = "\(major)-\(minor)"
        let locationName = firebaseManager.getLocationName(fromLocationID: locationID)
        
        // Get timestamp from Date(), username, trigger = triggerEvent
        let timestamp = Date()
        let triggerEvent = triggerEvent
        
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
