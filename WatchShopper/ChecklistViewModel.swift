//
//  ChecklistViewModel.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/10/21.
//

import Foundation

protocol ChecklistViewModelDelegate: AnyObject {
    func listDidUpdate(_ checklist: Checklist)
}

class ChecklistViewModel: ObservableObject {
    @Published var checklist: Checklist
    weak var delegate: ChecklistViewModelDelegate? = nil
    var sortTimer: Timer? = nil
    let sortTimeout: TimeInterval = 1
    
    init(checklist: Checklist, delegate: ChecklistViewModelDelegate? = nil) {
        self.checklist = checklist
        self.checklist.sortCheckedToBottom()
        self.delegate = delegate
    }
    
    func toggleChecked(for item: Checklist.Item) {
        checklist.toggle(item: item)
        resetSortTimer()
    }
    
    func resetSortTimer() {
        sortTimer?.invalidate()
        sortTimer = Timer.scheduledTimer(withTimeInterval: sortTimeout, repeats: false, block: {  [weak self] _ in
            self?.sortTimerFired()
        })
    }
    
    func sortTimerFired() {
        sortTimer?.invalidate()
        sortTimer = nil
        
        //Sort list items, sending completed/checked items to the bottom.
        checklist.sortCheckedToBottom()
        saveChecklist()
    }
    
    func saveChecklist() {
        delegate?.listDidUpdate(checklist)
    }
    
    func addItem(_ newItemText: String) {
        let newItem = Checklist.Item(title: newItemText, checked: false)
        checklist.items.insert(newItem, at: 0)
        checklist.sortCheckedToBottom()
        saveChecklist()
    }
    
    func delete(at indexSet: IndexSet) {
        for index in indexSet.reversed() {
            checklist.items.remove(at: index)
        }
        checklist.sortCheckedToBottom()
        saveChecklist()
    }
}
