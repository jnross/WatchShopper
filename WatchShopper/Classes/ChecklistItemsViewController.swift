//
//  ChecklistItemsViewController.swift
//  WatchShopper
//
//  Created by Joseph Ross on 1/1/19.
//  Copyright © 2019 Easy Street 3. All rights reserved.
//

import UIKit

class ChecklistItemsViewController: UITableViewController {
    @objc var checklist: Checklist!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.checklist.name
        self.checklist.observer = self
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checklist.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Item"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = checklist.items[indexPath.row]
        cell.textLabel?.text = item.name
        if item.checked {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        checklist.items[indexPath.row].checked.toggle()
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    @IBAction private func savePressed(_ sender: Any) {
        checklist.saveToEvernote()
    }
    
}

extension ChecklistItemsViewController: ChecklistObserver {
    func checklistDidRefresh(_: Checklist) {}
    
    func checklist(_: Checklist, updatedItem item: ChecklistItem) {
        let indexPath = IndexPath(row: Int(item.id), section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
