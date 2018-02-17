//
//  LastLocationsTableViewController.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 06/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit
import CoreData

class LocationsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    typealias Controller = NSFetchedResultsController<Person>

    var username: String?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private lazy var firstSection: Controller = self.fetchControllerFor(matchingName: true)
    private lazy var secondSection: Controller = self.fetchControllerFor(matchingName: false)
    
    var controllers: [Controller] { return [firstSection, secondSection] }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 80
        tableView.dataSource = self
        
        do {
            try firstSection.performFetch()
            try secondSection.performFetch()
        } catch {
            print("ERROR: Something went wrong fetching...")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func onSwitchAccount(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - NSFetchedResultsControllerDelegate methods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        tableView.reloadData()
    }
    
    private func fetchControllerFor(matchingName matching: Bool) -> Controller {
        let request: NSFetchRequest<Person> = NSFetchRequest<Person>(entityName: "Person")
                let predicate: NSPredicate = matching ?
                    NSPredicate(format: "\(#keyPath(Person.name)) == %@", self.username ?? "") :
                    NSPredicate(format: "\(#keyPath(Person.name)) != %@", self.username ?? "")
                request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let fetch = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        fetch.delegate = self
        return fetch
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return controllers.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return firstSection.sections?[0].numberOfObjects ?? 0
        case 1: return secondSection.sections?[0].numberOfObjects ?? 0
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "locationTableCell", for: indexPath) as? LocationsTableViewCell else {
            fatalError("dequeued cell is not a LocationsTableCell")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "My Location"
        case 1: return "All Locations"
        default: return ""
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? LocationsTableViewCell else {
            fatalError("cell to be displayed is not a LocationsTableViewCell")
        }
        
        let person: Person?
        
        switch indexPath[0] {
        case 0:
            person = self.firstSection.fetchedObjects![indexPath.row]
        case 1:
            person = self.secondSection.fetchedObjects![indexPath.row]
        default:
            person = self.firstSection.fetchedObjects![indexPath.row]
        }

        // Configure Cell
        cell.titleLabel?.text = person?.name
        cell.subtitleLabel?.text = "Subtitle"
        cell.imageView?.image = UIImage(data: (person?.profilePhoto)! as Data)
    }
}
