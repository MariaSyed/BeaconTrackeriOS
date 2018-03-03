//
//  ViewController.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 05/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
//  Login screen view controller, handles the login of the user and selects user image

import UIKit
import SVProgressHUD
import CoreLocation
import FirebaseStorage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    lazy var firebaseManager: FirebaseDatabaseManager = {
        return FirebaseDatabaseManager(context: context)
    }()
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var imageSelector: UIButton!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var enterButton: UIButton!
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        firebaseManager.observeAndSyncData()
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
        if let personName = nameField.text?.trimmingCharacters(in: .whitespaces), personName.count > 0 {
            enterButton.isEnabled = false
            SVProgressHUD.show()
            
            var imageData: Data?
            
            // Update profile picture if image changed
            if let img = imagePreview.image, img != UIImage(named: "SelectPhoto") {
                // Set new photo
                imageData = UIImageJPEGRepresentation(img, 0.3) ?? Data()
            }
            
        
            DispatchQueue.global().async {
                self.firebaseManager.savePerson(withName: personName, withImage: imageData, onCompletion: {
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        self.enterButton.isEnabled = true
                        self.resetFields()
                        self.navigateToLocations(name: personName, newPhotoSet: imageData != nil)
                    }
                }, onFailure: {
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        self.enterButton.isEnabled = true
                        let alert = UIAlertController(title: "Error", message: "Something went wrong while uploading your image. Check you have internet connection and Firebase storage daily quota limit not reached", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            }
          
        } else {
            // No name entered
            self.enterButton.isEnabled = true
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
    
    func navigateToLocations(name: String, newPhotoSet: Bool) {
        let locationsVC = self.storyboard!.instantiateViewController(withIdentifier: "LocationsTableViewController") as! LocationsTableViewController
        locationsVC.username = name
        locationsVC.newPhotoSet = newPhotoSet
        locationsVC.firebaseManager = self.firebaseManager
        
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

