//
//  ReminderListViewController.swift
//  injectReminders
//
//  Created by Waddah Al Drobi on 2018-07-18.
//  Copyright © 2018 Waddah Al Drobi. All rights reserved.
//

import Foundation
import UIKit
import EventKit

class ReminderListViewController: UITableViewController {
    var calendars: [EKCalendar] = []
    var current_cal: EKCalendar?
    
    override func viewDidLoad() {
        get_calendars { [weak self]
            calendars in
            get_calendar {
                current_cal in
                
                self?.current_cal = current_cal
                self?.calendars = calendars
                self?.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.calendars.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let calendar = self.calendars[indexPath.item]
        
        if calendar.calendarIdentifier == self.current_cal?.calendarIdentifier {
            cell.textLabel?.font = UIFont(name: "AvenirNext-Bold", size: 16.0)
            cell.textLabel?.text = "‣ \(calendar.title)"
        }
        else {
            cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
            cell.textLabel?.text = calendar.title
        }
        
        return cell
    }
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let calendar = self.calendars[indexPath.item]
        set_calendar(calendar)
        
        currentRemidnerList.loadFromCalendar(loadCompletedItems: false)
        self.dismiss(animated: true, completion: nil)
        
        return nil
    }
}
