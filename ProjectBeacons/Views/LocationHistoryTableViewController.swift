//
//  LocationHistoryTableViewController.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 17/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit

class LocationHistoryTableViewController: UITableViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var beaconEvents: [BeaconEvent]?
    var sections: [Int: [Any]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let ev1 = BeaconEvent(context:context)
//        ev1.locationID = "0-1"
//        ev1.locationName = "Metro1"
//        ev1.timestamp = Date(timeIntervalSinceNow: 100)
//        
//        let ev2 = BeaconEvent(context:context)
//        ev2.locationID = "0-1"
//        ev2.locationName = "Metro1"
//        ev2.timestamp = Date(timeIntervalSinceNow: 60)
//        
//        let ev3 = BeaconEvent(context:context)
//        ev3.locationID = "1-3"
//        ev3.locationName = "Metro3"
//        ev3.timestamp = Date(timeIntervalSinceNow: 20)
//        
//        beaconEvents = [ev1, ev2, ev3]
        print("beacon events: \(beaconEvents)")
        if let events = beaconEvents {
            sections = getDictionaryOfSections(beaconEvents: events )
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private functions
    
    @IBAction func onBackPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getDictionaryOfSections (beaconEvents: [BeaconEvent]) -> [Int: [Any]] {
        var dictionaryOfSections = [Int: [Any]]()

        let location: Location? = getMostRepeatedLocation(beaconEvents: beaconEvents)
        if let location = location {
            dictionaryOfSections[0] = [location]
        }
        
        dictionaryOfSections[1] = beaconEvents
    
        return dictionaryOfSections
    }
    
    func getMostRepeatedLocation(beaconEvents: [BeaconEvent]) -> Location? {
        // Create dictionary to map value to count
        var counts = [String: Int]()
        
        // Count the values with using forEach
        beaconEvents.forEach { beaconEvent in
            counts[beaconEvent.locationID!] = (counts[beaconEvent.locationID!] ?? 0) + 1
        }
        
        // Find the most frequent event and its count with max
        if let (locationID, count) = counts.max(by: {$0.1 < $1.1}) {
            let filteredEventsByID = beaconEvents.filter{beaconEvent in
                return beaconEvent.locationID == locationID
            }
            
            let mostRecentBeaconEvent = filteredEventsByID.reduce(filteredEventsByID[0], { $0.timestamp!.timeIntervalSince1970 > $1.timestamp!.timeIntervalSince1970 ? $0 : $1 })
            
            let timeSinceLastVisit = Int((mostRecentBeaconEvent.timestamp?.timeIntervalSinceNow)! / 60)
            return Location(locationName: mostRecentBeaconEvent.locationName ?? "", numberOfVisits: count, timeSinceLastVisit: timeSinceLastVisit)
        } else {
            return nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = sections[section]?.count {
            return count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "locationHistoryTableCell", for: indexPath) as? LocationHistoryTableViewCell else {
            fatalError("Cell dequeued was not a LocationHistoryTableViewCell")
        }
        
        
        switch (indexPath.section) {
        case 0:
            let object = sections[0]![indexPath.row] as! Location
            cell.titleLabel.text = object.locationName
            cell.subtitleLabel.text = "visited \(object.numberOfVisits ?? 0) times, last visited \(object.timeSinceLastVisit ?? 0) min ago"
        case 1:
            if let section = sections[1] {
                let object = section[indexPath.row] as! BeaconEvent
                let minSinceLastVisit = Int((object.timestamp?.timeIntervalSinceNow)! / 60)
                cell.titleLabel.text = "\(object.triggerEvent ?? "") \(object.locationName ?? "")"
                cell.subtitleLabel.text = "visited \(minSinceLastVisit) min ago"
            }
        default:
            cell.titleLabel.text = "None"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return "Most Popular"
        case 1:
            return "Past Locations"
        default:
            return "Past Locations"
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
