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
        
        if let events = beaconEvents {
            sections = getDictionaryOfSections(beaconEvents: events )
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    @IBAction func onBackPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getDictionaryOfSections (beaconEvents: [BeaconEvent]) -> [Int: [Any]] {
        var dictionaryOfSections = [Int: [Any]]()

        let location: MostPopularLocation? = getMostRepeatedLocation(beaconEvents: beaconEvents)
        if let location = location {
            dictionaryOfSections[0] = [location]
        }
        
        dictionaryOfSections[1] = beaconEvents.sorted(by: { $0.timestamp!.compare($1.timestamp! as Date) == .orderedDescending })
    
        return dictionaryOfSections
    }
    
    func getMostRepeatedLocation(beaconEvents: [BeaconEvent]) -> MostPopularLocation? {
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
            
            let latestTimestamp = mostRecentBeaconEvent.timestamp
            return MostPopularLocation(locationID: mostRecentBeaconEvent.locationID ?? "", locationName: mostRecentBeaconEvent.locationName ?? "", numberOfVisits: count, latestTimestamp: latestTimestamp)
        } else {
            return nil
        }
    }

    // MARK: - TableViewDataSource Methods

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
    
    // Mark: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? LocationHistoryTableViewCell else {
            fatalError("cell to be displayed is not a LocationsTableViewCell")
        }
        
        switch (indexPath.section) {
        case 0:
            let object = sections[0]![indexPath.row] as! MostPopularLocation
            cell.titleLabel.text = object.locationName
            cell.timesVisitedLabel.text = "Visited \(object.numberOfVisits ?? 0) times"
            cell.lastVisitedLabel.text = "Last visited at \(object.latestTimestamp?.convertToFormat(format: " HH:mm dd/MM/yyy") ?? "---")"
            cell.profileImage.image = UIImage(named: object.locationID ?? "SelectPhoto")
        case 1:
            if let section = sections[1] {
                let object = section[indexPath.row] as! BeaconEvent
                let minSinceLastVisit = Int((object.timestamp?.timeIntervalSinceNow)! / 60).magnitude
                
                cell.titleLabel.text = "\(object.triggerEvent ?? "") \(object.locationName ?? "")"
                cell.profileImage.image = UIImage(named: object.locationID ?? "SelectPhoto")
                
                if minSinceLastVisit > 90 {
                    cell.timesVisitedLabel.text = "Visited at \(object.timestamp?.convertToISO() ?? "---")"
                } else {
                    cell.timesVisitedLabel.text = "Visited \(minSinceLastVisit) min ago"
                }
            }
        default:
            cell.titleLabel.text = "None"
        }
    }
}
