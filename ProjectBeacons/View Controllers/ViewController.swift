//
//  ViewController.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 05/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    lazy var firebaseManager: FirebaseDatabaseManager = {
        return FirebaseDatabaseManager(context: context)
    }()
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var imageSelector: UIButton!
    @IBOutlet weak var imagePreview: UIImageView!
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
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
            // Save to rtdb
            firebaseManager.savePerson(withName: personName)
            
            self.resetFields()
            self.navigateToLocations(name: personName)
        } else {
            // No name entered
            let alert = UIAlertController(title: "Name required", message: "You need to enter your name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Private Methods
    
    func resetFields() {
        guard let selectPhoto = UIImage(named: "SelectPhoto") else {
            fatalError("could not find select photo in image assets!")
        }
        nameField.text = ""
        imagePreview.image = selectPhoto
    }
    
    func navigateToLocations(name: String) {
        let locationsVC = self.storyboard!.instantiateViewController(withIdentifier: "LocationsTableViewController") as! LocationsTableViewController
        locationsVC.username = name
        let navController = UINavigationController(rootViewController: locationsVC)
        self.present(navController, animated: true)
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing value of type image instead got \(info)")
        }
        
        // Preview selected image
        imagePreview.image = selectedImage
        
        dismiss(animated: true, completion: nil)
    }
}

