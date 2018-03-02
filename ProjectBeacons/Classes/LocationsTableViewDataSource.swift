//
//  LocationsDataSource.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 02/03/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit
import CoreData

class LocationsTableViewDataSource: NSObject, UITableViewDataSource {
    typealias Controller = NSFetchedResultsController<Person>
    
    private var context: NSManagedObjectContext!
    
    private lazy var firstSection: Controller = self.fetchControllerFor(matchingName: true)
    private lazy var secondSection: Controller = self.fetchControllerFor(matchingName: false)
    
    var matchingName: String = ""
    
    var controllers: [Controller] { return [firstSection, secondSection] }
    
    init(context: NSManagedObjectContext, matchingName: String) {
        self.context = context
        self.matchingName = matchingName
        super.init()
    }
    
    public func refetchFRC() {
        do {
            try firstSection.performFetch()
            try secondSection.performFetch()
        } catch {
            print("fetched results controller perform fetch failed")
        }
    }
    
    public func getPerson(atIndexPath indexPath: IndexPath) -> Person {
        var person: Person
        
        switch indexPath.section {
        case 0:
            person = self.firstSection.fetchedObjects![indexPath.row]
        case 1:
            person = self.secondSection.fetchedObjects![indexPath.row]
        default:
            person = self.firstSection.fetchedObjects![indexPath.row]
        }
        
        return person
    }
    
    // Mark: - Private Methods
    
    private func fetchControllerFor(matchingName matching: Bool) -> Controller {
        let request: NSFetchRequest<Person> = NSFetchRequest<Person>(entityName: "Person")
        let predicate: NSPredicate = matching ?
            NSPredicate(format: "\(#keyPath(Person.name)) ==[cd] %@", matchingName) :
            NSPredicate(format: "\(#keyPath(Person.name)) !=[cd] %@", matchingName)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let fetch = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetch
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return controllers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return firstSection.sections?[0].numberOfObjects ?? 0
        case 1: return secondSection.sections?[0].numberOfObjects ?? 0
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "locationTableCell", for: indexPath) as? LocationsTableViewCell else {
            fatalError("dequeued cell is not a LocationsTableCell")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "My Location"
        case 1: return "All Locations"
        default: return ""
        }
    }
}
