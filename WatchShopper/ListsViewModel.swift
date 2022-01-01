//
//  ListsViewModel.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

class ListsViewModel: ObservableObject, WatchSyncDelegate, ChecklistViewModelDelegate {
    @Published var lists: [Checklist]
    private let sync = WatchSync()
    
    init(lists: [Checklist]) {
        self.lists = lists
        sync.delegate = self
        sortLists()
    }
    
    private func sortLists() {
        lists.sort { $0.updated > $1.updated }
    }
    
    func syncToWatch() {
        sync.updateLists(lists: lists)
    }

//MARK: WatchSyncDelegate
    func listUpdated(list: Checklist) {
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index] = list
        } else {
            lists.append(list)
            sortLists()
        }
    }
    
    func listsUpdated(lists: [Checklist]) {
        DispatchQueue.main.async {
            self.lists = lists
            self.sortLists()
        }
    }

//MARK: ChecklistViewModelDelegate
    func listDidUpdate(_ checklist: Checklist) {
        if let index = lists.firstIndex(where: { $0.id == checklist.id }) {
            lists[index] = checklist
        } else {
            lists.append(checklist)
            sortLists()
        }
        sync.updateLists(lists: lists)
    }
}
