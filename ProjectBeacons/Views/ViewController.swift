//
//  ViewController.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 05/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var imageSelector: UIButton!
    @IBOutlet weak var imagePreview: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.navigationBar.topItem?.title = "Switch account"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBActions
    
    @IBAction func onImageSelect(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func onEnter(_ sender: UIButton) {
        if let personName = nameField.text, personName.count > 0 {
            var person : Person? = nil
            
            do {
                person = try Person.getOrCreatePersonWith(name: personName, context: context)
            } catch {
                print("Error creating person: \(error)")
            }
            
            if let uniquePerson = person {
//                let beaconEvent: BeaconEvent = BeaconEvent(context: context)
//                beaconEvent.locationID = "0-1"
//                beaconEvent.locationName = "Metropolia B110"
//                beaconEvent.major = "0"
//                beaconEvent.minor = "1"
//                beaconEvent.timestamp = Date()
//                beaconEvent.triggerEvent = "ENTER"
                uniquePerson.name = personName
//                uniquePerson.addToBeaconEvents(beaconEvent)
                // Update profile picture if image changed
                if let img = imagePreview.image, img != UIImage(named: "SelectPhoto") {
                    // Set new photo
                    if let image = imagePreview.image {
                        uniquePerson.profilePhoto = UIImagePNGRepresentation(image)! as NSData
                    }
                }
                try? context.save()
                self.resetFields()
                
                self.navigateToLocations(person: uniquePerson)
            }
            
        } else {
            // No name entered
            let alert = UIAlertController(title: "Name required", message: "You need to enter your name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Private functions
    
    func resetFields() {
        guard let selectPhoto = UIImage(named: "SelectPhoto") else {
            fatalError("could not find select photo in image assets!")
        }
        nameField.text = ""
        imagePreview.image = selectPhoto
    }
    
    func navigateToLocations(person: Person) {
        let locationsVC = self.storyboard!.instantiateViewController(withIdentifier: "LocationsTableViewController") as! LocationsTableViewController
        locationsVC.username = person.name
        let navController = UINavigationController(rootViewController: locationsVC)
        self.present(navController, animated: true)
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Espected a dictionary containiing value of type image instead got \(info)")
        }
        
        // Preview selected image
        imagePreview.image = selectedImage
        
        dismiss(animated: true, completion: nil)
    }


}

