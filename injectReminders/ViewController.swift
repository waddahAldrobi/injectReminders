//
//  ViewController.swift
//  injectReminders
//
//  Created by Waddah Al Drobi on 2018-06-28.
//  Copyright © 2018 Waddah Al Drobi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var navbarTitle: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reminderListWasChanged(_:)), name: NSNotification.Name(rawValue: "reminderListChanged"), object: currentRemidnerList)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setup_ui()
        super.viewWillAppear(animated)
        
        print("List: \(currentRemidnerList.currentReminders())")
    }

    @IBAction func addButton(_ sender: Any) {
    }
    
    @IBAction func clearAction(_ sender: Any) {
    currentRemidnerList.loadFromCalendar(loadCompletedItems: false)
        self.clearButton.isHidden = true
    }
    
    func setup_ui() {
        get_calendar { [weak self]
            calendar in
            let title = calendar.title
            self?.navbarTitle?.title = title
        }
   
        self.tableView.reloadData()
        
        if currentRemidnerList.hasAnyCompletedItems() {
            self.clearButton.isHidden = false
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.clearButton.frame.height, right: 0)
        }
        else {
            self.clearButton.isHidden = true
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    @objc func addReminder() {
        self.performSegue(withIdentifier: "addReminder", sender: nil)
    }
    
    @objc func reminderListWasChanged(_ notification: NSNotification!) {
        DispatchQueue.main.async {
            self.setup_ui()
        }
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // special case for empty, "add reminder" cell
        if indexPath.item >= currentRemidnerList.count {
            return nil
        }
        
        let reminder = currentRemidnerList[indexPath.item]
        reminder.toggle_done()
        self.setup_ui()
        return nil
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentRemidnerList.count + 1
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // special case for empty, "add reminder" cell
        if indexPath.item >= currentRemidnerList.count {
            return false
        }
        return true
    }
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        
        let reminder = currentRemidnerList[indexPath.item]
        currentRemidnerList.delete(reminder)
        
        tableView.deleteRows(at:[indexPath], with: .automatic)
    }
    
    // Data added here
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        if indexPath.item < currentRemidnerList.count {
            let selected_bg_view = UIView()
            selected_bg_view.backgroundColor = StyleKit.orangeWhite()
            cell.selectedBackgroundView = selected_bg_view
        }
        else {
            let button = UIButton(frame: cell.frame)
            button.backgroundColor = UIColor.clear
            button.addTarget(self, action: #selector(ViewController.addReminder), for: .touchUpInside)
            cell.addSubview(button)
            cell.selectionStyle = .none
        }
        
        // special case for empty, "add reminder" cell
        if indexPath.item >= currentRemidnerList.count {
            return cell
        }
        
        let reminder = currentRemidnerList[indexPath.item]
        
        cell.textLabel?.text = reminder.name
        
        print("Dates: \(reminder.dueDate)")
        
        let today = UserDefaults.standard.object(forKey: "date") as? Date
//        cell.detailTextLabel?.text = today?.toString(dateFormat: "h:mm a 'on' MMMM dd, yyyy")
        cell.detailTextLabel?.text = reminder.dueDate
        cell.detailTextLabel?.textColor = .gray
        
        cell.imageView?.image = StyleKit.imageOfCheckbox(withIsChecked: reminder.done)
        if reminder.done {
            cell.accessibilityHint = "checks off \(reminder.name)"
        }
        else {
            cell.accessibilityHint = "unchecks \(reminder.name)"
        }
        
        return cell
    }
}

// popover related code
var addReminderTransitionDelegate = ZippyModalTransitioningDelegate()

extension ViewController: UIPopoverPresentationControllerDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueid = segue.identifier
        if (segueid == "showPopover") {
            let destinationVC = segue.destination
            destinationVC.modalPresentationStyle = .popover
            destinationVC.popoverPresentationController?.delegate = self
        }
        else if segueid == "addReminder" {
            let destinationVC = segue.destination
            destinationVC.modalPresentationStyle = .custom
            destinationVC.transitioningDelegate = addReminderTransitionDelegate
        }
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        return dateFormatter.string(from: self)
    }
    
}



