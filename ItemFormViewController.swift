//
//  ItemFormViewController.swift
//  nv-comms
//
//  Created by Denis Quaid on 15/03/2017.
//  Copyright © 2017 dquaid. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import UserNotifications

protocol ItemFormDelegate {
    func saveItem(title: String, date: Date, image: UIImage?, countDown: String, alertOn: Bool)
    func addNewImage()
}

func getDocumentsURL() -> NSURL {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return documentsURL as NSURL
}

func fileInDocumentsDirectory(filename: String) -> String {
    
    let fileURL = getDocumentsURL().appendingPathComponent(filename)
    return fileURL!.path
}

class ItemFormViewController: UIViewController, ItemFormDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var itemFormView: ItemFormView?
    var imagePicker: UIImagePickerController?
    
    // Define the specific path, image name
    let imagePath:  String? = nil //fileInDocumentsDirectory(myImageName)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Create New Item"
        self.itemFormView?.delegate = self
        self.imagePicker = UIImagePickerController()
    }
    
    private func saveImage (image: UIImage?, path: String ){
        if (image != nil) {
            let pngImageData = UIImagePNGRepresentation(image!)
            let pathUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(path).png")
            print("Saving to \(pathUrl)")
            do {
                try pngImageData!.write(to: pathUrl, options: .atomic)
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
    }
    
    private func setLocalNotification(text: String, date: Date) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Countday Alert"
        content.body = text
        content.sound = UNNotificationSound.default()
        
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "UYLLocalNotification" + text
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
        })
    }
    
    @IBAction func didDismissForm() {
        self.dismiss(animated: true)
    }
    
    // MARK: - ItemForm Delegate Methods
    
    func saveItem(title: String, date: Date, image: UIImage?, countDown: String, alertOn: Bool) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)!
        let item = NSManagedObject(entity: entity, insertInto: managedContext)
        let dateString = date.stringForDate()
        item.setValue(title, forKeyPath: "title")
        item.setValue(dateString, forKeyPath: "dateString")
        item.setValue(countDown, forKey: "countDown")
        
        if (alertOn) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { (settings) in
                if settings.authorizationStatus != .authorized {
                    // Notifications not allowed
                }
                else {
                    self.setLocalNotification(text: title, date: date)
                }
            }
        }
        
        self.saveImage(image: image, path:title )
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        self.dismiss(animated: true)
    }
    
    func addNewImage() {
        guard let imagePicker = self.imagePicker else {
            return
        }
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            guard let imageView = self.itemFormView?.imageView else {
                print("Invalid image view")
                return
            }
            
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}

class ItemFormView : UIView {
    
    @IBOutlet var titleTextField: UITextField?
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var datePickerExpandView: UIView?
    @IBOutlet var datePicker: UIDatePicker?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var alertSwitcher: UISwitch?
    
    @IBOutlet var datePickerViewHeight: NSLayoutConstraint?
    
    var delegate: ItemFormDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.datePickerViewHeight?.constant = CGFloat(0)

        let dateString = self.datePicker?.date.stringForDate()
        self.dateLabel?.text = dateString
        self.datePicker?.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
    }
    
    func willMoveToSuperview(newSuperview: UIView) {
        super.willMove(toSuperview: newSuperview)
    }
    
    @IBAction func didSelectDatePicker() {
        // toggle the constraints of the datePickerView
        let collapsed = self.datePickerViewHeight?.constant == CGFloat(0)
        if !collapsed {
            self.datePickerViewHeight?.constant = CGFloat(0)
        } else {
            self.datePickerViewHeight?.constant = CGFloat(216)
        }
    }
    
    @objc func datePickerChanged() {
        let newDate = self.datePicker?.date
        let dateString = newDate?.stringForDate()
        self.dateLabel?.text = dateString
    }
    
    @IBAction func didAddNewItem(sender: Any) {
        guard let title: String = self.titleTextField?.text,
            let date: Date = self.datePicker?.date else {
                return
        }
        
        // Get the days between both dates
        // TODO: Handle negatives
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents(Set(arrayLiteral: .day, .hour), from: currentDate, to: date)
        
        let days = String(describing: components.day!)
        
        let image: UIImage? = self.imageView?.image
        guard let alertOn: Bool = self.alertSwitcher?.isOn else {
            return
        }
        
        self.delegate?.saveItem(title: title, date: date, image: image, countDown: days, alertOn: alertOn)
    }
    
    @IBAction func addNewImage(sender: Any) {
        self.delegate?.addNewImage()
    }
    
}

fileprivate extension Date {
    
    func stringForDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        return dateFormatter.string(from: self)
    }
    
}
