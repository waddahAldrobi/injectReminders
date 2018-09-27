//
//  reminderClass.swift
//  injectReminders
//
//  Created by Waddah Al Drobi on 2018-06-28.
//  Copyright © 2018 Waddah Al Drobi. All rights reserved.
//

import Foundation
import EventKit


class Reminders {
    var name: String
    var dueDate: String
    var done: Bool = false
    var reminder: EKReminder
    var created: Date? {
        return self.reminder.creationDate
    }
    var completed_date: Date? {
        return self.reminder.completionDate
    }
    
    init(name: String, done: Bool, reminder: EKReminder, dueDate: String) {
        self.name = name
        self.done = done
        self.reminder = reminder
        self.dueDate = dueDate
    }
    convenience init?(reminder: EKReminder) {
        guard let name = reminder.title else {
            return nil
        }
        
        guard let dueDate = reminder.dueDateComponents else {
            return nil
        }
        
        let date = "\(String(dueDate.year!))-\(String(dueDate.day!))-\(String(dueDate.month!)) , \(String(dueDate.hour!)):\(String(dueDate.minute!))" 
        
        self.init(name: name, done: reminder.isCompleted, reminder: reminder, dueDate: date)
    }
    
    func toggle_done() {
        done = !done
        reminder.isCompleted = done
        save_reminder(reminder) {}
    }
}

class RemindersList {
    var list: Array<Reminders>
//    var listDates : Array<Reminders>
    
    var count: Int {
        return self.list.count
    }
    
    init(reminders: Array<Reminders>) {
        self.list = reminders
    }
    convenience init() {
        self.init(reminders: [])
    }
    
    subscript(index: Int) -> Reminders {
        get {
            return self.list[index]
        }
    }
    func currentReminders() -> Array<Reminders> {
        return self.list.filter() { !$0.done }
    }
    
    func sendChangedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reminderListChanged"), object: self)
    }
    
    func add(_ name: String) {
        create_reminder(name) {
            reminder in
            
            guard let addedReminder = Reminders(reminder: reminder) else {
                return
            }
            
            self.list.append(addedReminder)
            self.sendChangedNotification()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reminderAdded"), object: self, userInfo: ["reminder": addedReminder])
        }
    }
    func delete(_ deletedReminder: Reminders) {
        delete_reminder(deletedReminder.reminder)
        self.list = self.list.filter() { $0 !== deletedReminder }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reminderDeleted"), object: self, userInfo: ["reminder": deletedReminder])
    }
}

extension RemindersList {
    func hasAnyCompletedItems() -> Bool {
        for item in self.list {
            if item.done {
                return true
            }
        }
        return false
    }
}

extension RemindersList {
    func get_top(_ n: Int?, by_sort: (Reminders, Reminders) -> Bool) -> [Reminders] {
        let n_: Int
        if n == nil || n! > self.list.endIndex {
            n_ = self.list.endIndex
        }
        else {
            n_ = n!
        }
        
        let sorted_reminders = self.list.sorted {
            switch ($0.created, $1.created) {
            case (nil, _):
                return false
            case (_, nil):
                return true
            default:
                return $0.created!.timeIntervalSince($1.created!) > 0
            }
        }
        
        return Array(sorted_reminders[0..<n_])
    }
    func mostRecentlyAdded(_ n: Int? = nil) -> [Reminders] {
        return self.get_top(n) {
            switch ($0.created, $1.created) {
            case (nil, _):
                return false
            case (_, nil):
                return true
            default:
                return $0.created!.timeIntervalSince($1.created!) > 0
            }
        }
    }
    func mostRecentlyCompleted(_ n: Int? = nil) -> [Reminders] {
        return self.get_top(n) {
            switch ($0.completed_date, $1.completed_date) {
            case (nil, _):
                return false
            case (_, nil):
                return true
            default:
                return $0.created!.timeIntervalSince($1.created!) > 0
            }
        }
    }
}

func name_set(_ reminders: Array<Reminders>) -> NSSet {
    return NSSet(array: reminders.map {
        $0.name.lowercased()
    })
}


