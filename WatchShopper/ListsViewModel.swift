//
//  ListsViewModel.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

class ListsViewModel: ObservableObject {
    @Published var lists: [Checklist]
    
    init(lists: [Checklist]) {
        self.lists = lists
        sortLists()
    }
    
    func sortLists() {
        lists.sort { $0.updated > $1.updated }
    }
}

extension ListsViewModel: ChecklistViewModelDelegate {
    func checklistShouldSave(checklist: Checklist) {
        if let index = lists.firstIndex(where: { $0.id == checklist.id }) {
            lists[index] = checklist
        } else {
            lists.append(checklist)
            sortLists()
        }
    }
}

protocol ChecklistViewModelDelegate: AnyObject {
    func checklistShouldSave(checklist: Checklist)
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
        print(checklist.debugDescription)
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
    }
    
    func saveChecklist() {
        delegate?.checklistShouldSave(checklist: checklist)
    }
}
