//
//  Person+CoreDataClass.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 17/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
//

import Foundation
import UIKit
import CoreData

@objc(Person)
public class Person: NSManagedObject {

    class func getOrCreatePersonWith(name: String, context: NSManagedObjectContext) throws -> Person? {
        let request: NSFetchRequest<Person> = Person.fetchRequest()

        // match with name
        request.predicate = NSPredicate(format: "name =[cd] %@", name)

        do {
            let matchingPersons = try context.fetch(request)
            if matchingPersons.count == 1 {
                return matchingPersons[0]
            } else if matchingPersons.count == 0 {
                let newPerson = Person (context: context)
                return newPerson
            } else {
                print("Database inconsistent, found equal persons")
                return matchingPersons[0]
            }
        } catch {
            throw error
        }
    }

}
