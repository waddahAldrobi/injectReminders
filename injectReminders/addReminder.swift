//
//  addReminder.swift
//  injectReminders
//
//  Created by Waddah Al Drobi on 2018-07-09.
//  Copyright © 2018 Waddah Al Drobi. All rights reserved.
//

import Foundation
import UIKit
import EventKit


class addReminder: UIViewController {
    
    @IBOutlet weak var reminderName: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reminderName.delegate = self
        datePicker.date = Date()
        datePicker.minimumDate = Date()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        reminderName.becomeFirstResponder()
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.close()
    }

    @IBAction func saveButton(_ sender: Any) {
        createReminderAndClose(reminderName.text!)
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createReminderAndClose(_ reminderText: String) {
        if !reminderText.isEmpty {
            currentRemidnerList.add(reminderText)
        }
        self.close()
    }
   
    @IBAction func dateChanged(_ sender: Any) {
        let date = datePicker.date
        datePicker.minimumDate = Date()
        UserDefaults.standard.set(date, forKey: "date")
        
    }
    
}

extension addReminder : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        reminderName.resignFirstResponder()
        return false
    }
}

