//
//  calendarAdapter.swift
//  injectReminders
//
//  Created by Waddah Al Drobi on 2018-06-28.
//  Copyright © 2018 Waddah Al Drobi. All rights reserved.
//

import EventKit
import UIKit

func send_user_to_settings(_ current_view_controller: UIViewController! = nil) {
    var current_vc = current_view_controller
    if current_vc == nil {
        if let vc = UIApplication.shared.keyWindow?.rootViewController {
            if vc.isViewLoaded && vc.view.window != nil {
                current_vc = vc
            }
        }
    }
    
    // if nothing was passed in and we couldn't find a VC to use, give up
    if current_vc == nil {
        return
    }
    
    DispatchQueue.main.async {
        let alert = UIAlertController(title: "Reminders Access", message: "This app needs to access to your Reminders to work. This lets you add studying reminders with Siri, sync with iCloud, and share your study list.\n\nReminders are in the privacy section of this app’s settings.", preferredStyle: .alert)
        
        let default_action = UIAlertAction(title: "Open Settings", style: .default) { action in
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:])
                }
            }
        }
        
        alert.addAction(default_action)
        
        current_vc?.present(alert, animated: true, completion: nil)
        return
    }
}

func get_estore_permission(completed: @escaping (Bool) -> Void) {
    switch EKEventStore.authorizationStatus(for: EKEntityType.reminder) {
    case .notDetermined:
        EKEventStore().requestAccess(to: EKEntityType.reminder) {
            (granted: Bool, err: Error?) in
            if granted && (err == nil) {
                completed(true)
            }
            else {
                completed(false)
            }
        }
    case .authorized:
        completed(true)
    default:
        completed(false)
    }
}

var _estore: EKEventStore!
func get_estore(completed: @escaping (EKEventStore) -> ()) {
    if _estore != nil {
        completed(_estore)
        return
    }
    
    _estore = EKEventStore()
    
    get_estore_permission {
        permission in
        if permission {
            completed(_estore)
        }
        else {
            _estore = nil
            send_user_to_settings()
        }
    }
}
// Asks for the permission
func app_has_estore_permission() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    return status == .authorized;
}

// Gets the calendars that are in popover
func get_calendars(completed: @escaping (([EKCalendar])->())) {
    get_estore {
        estore in
        
        let cals = estore.calendars(for: .reminder)
        completed(cals)
    }
}

// Defaults the calendar, and creates "Notonian" Calendar
func get_default_calendar(completed: @escaping (EKCalendar) -> () ) {
    get_calendars {
        calendars in
        
        let cals = calendars.filter() {
            switch $0.title.lowercased() {
            case "Notonian":
                return true
            default:
                return false
            }
        }
        if cals.count > 0 {
            completed(cals[0])
        }
        else {
            create_calendar("Notonian") {
                cal in
                completed(cal)
            }
        }
    }
}

// Creates a calendar in the reminders app
func create_calendar(_ name: String, completed: @escaping (EKCalendar)->Void) {
    get_estore {
        estore in
        
        let cal = EKCalendar(for: .reminder, eventStore: estore)
        cal.title = name
        cal.source = estore.defaultCalendarForNewReminders()!.source
        
        do {
            try estore.saveCalendar(cal, commit: true)
        }
        catch let err {
            print(err)
        }
        
        completed(cal)
    }
}

// Gets a specific calendar
var calendar: EKCalendar!
func get_calendar(_ completed: @escaping (EKCalendar)->()) {
    if calendar != nil {
        completed(calendar)
        return
    }
    
    let user_defaults = UserDefaults.standard
    
    get_estore {
        estore in
        
        if let calendar_id = user_defaults.string(forKey: "calendar_id") {
            if let cal = estore.calendar(withIdentifier: calendar_id) {
                
                calendar = cal
                completed(cal)
                return
            }
        }
        
        get_default_calendar {
            cal in

            set_calendar(cal)
            completed(cal)
        }
    }
}

// Sets the calendar when it is clicker
func set_calendar(_ cal: EKCalendar) {
    let user_defaults = UserDefaults.standard
    user_defaults.set(cal.calendarIdentifier, forKey: "calendar_id")
    
    calendar = cal
}

// gets current calendar and estore
func get_estore_and_calendar(completed: @escaping (EKEventStore, EKCalendar) -> ()) {
    get_estore { estore in
        get_calendar { calendar in
    
            completed(estore, calendar)
        }
    }
}

// ############# Not really sure what it does, possiblly remove
func get_reminder_with_identifier(_ identifier: String, completed: @escaping (EKReminder) -> Void) {
    get_estore {
        (estore: EKEventStore) in
        let event = estore.calendarItem(withIdentifier: identifier) as! EKReminder
        completed(event)
    }
}

extension RemindersList {
    
    // Load the reminders from a calendar as objects not really as names, they're hard to access
    func loadFromCalendar(loadCompletedItems: Bool = false, complete: (()->Void)? = nil) {
        get_estore_and_calendar { [weak self]
            (estore, calendar) in
            
            var remindersPredicate: NSPredicate
            
            if loadCompletedItems {
                remindersPredicate = estore.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: [calendar])
            }
            else {
                remindersPredicate = estore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])
            }
            
            estore.fetchReminders(matching: remindersPredicate) {
                reminders in
                guard let strong_self = self, let reminders = reminders else {
                    if let cb = complete {
                        cb()
                    }
                    return
                }
                strong_self.list = reminders.compactMap {
                    Reminders(reminder: $0)
                }
                
                print("strong_self.list: \(strong_self.list)")
                
                DispatchQueue.main.async {
                    if let strong_self = self {
                        strong_self.sendChangedNotification()
                    }
                    if let cb = complete {
                        cb()
                    }
                }
            }
        }
    }
    
    func updateFromCalendar(loadCompletedItems: Bool, keepCurrent: Bool, complete: (()->Void)? = nil) {
        get_estore_and_calendar { [weak self]
            (estore, calendar) in
            guard let strong_self = self else {
                return
            }
            let current_reminder_ids = NSSet(array: strong_self.list.map { $0.reminder.calendarItemIdentifier })
            let predicate = estore.predicateForReminders(in: [calendar])
            
            estore.fetchReminders(matching: predicate) {
                reminders in
                guard let strong_self = self else {
                    if let cb = complete {
                        cb()
                    }
                    return
                }
                guard let reminders = reminders else {
                    if let cb = complete {
                        cb()
                    }
                    return
                }
                
                print("reminders: \(reminders)")
                
                strong_self.list = reminders.filter { reminder in
                    if keepCurrent && current_reminder_ids.contains(reminder.calendarItemIdentifier) {
                        return true
                    }
                    
                    if loadCompletedItems {
                        return reminder.isCompleted
                    }
                    else {
                        return !reminder.isCompleted
                    }
                    }.flatMap {
                        Reminders(reminder: $0)
                }
                
                DispatchQueue.main.async {
                    if let strong_self = self {
                        strong_self.sendChangedNotification()
                    }
                    if let cb = complete {
                        cb()
                    }
                }
            }
        }
    }
}

// Creates and saves reminder
func create_reminder(_ name: String, completed: @escaping (EKReminder) -> ()) {
    get_estore {
        estore in
        get_calendar {
            calendar in
            
            let reminder = EKReminder(eventStore: estore)
            reminder.title = name
            reminder.isCompleted = false
            reminder.calendar = calendar
            
            
            // *** Create date ***
            let date = UserDefaults.standard.object(forKey: "date")
            
            // *** create calendar object ***
            let calendarFlag = NSCalendar.current
            
            let alarm = EKAlarm(absoluteDate: date as! Date)
            // Set compontents to reminder
            reminder.dueDateComponents = calendarFlag.dateComponents([.year, .month, .day, .hour, .minute], from: date as! Date)
            reminder.addAlarm(alarm)
            
            
            completed(reminder)
            
            save_reminder(reminder) {}
        }
    }
}

// Saves reminder after being created
func save_reminder(_ reminder: EKReminder, completed: @escaping () -> ()) {
    get_estore {
        estore in
        
        do {
            try estore.save(reminder, commit: true)
        }
        catch let err {
            print(err)
        }
        
        completed()
    }
}

// Deletes a reminder
func delete_reminder(_ reminder: EKReminder) {
    get_estore {
        estore in
        try? estore.remove(reminder, commit: true)
    }
}
