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
    
    // Retry logic
    private var refreshRetryCount = 0
    private let maxRefreshRetries = 3
    private var refreshRetryTimer: Timer?
    private var didReceiveLists = false
    
    init(lists: [Checklist]) {
        self.lists = lists
        sync.delegate = self
        sortLists()
    }
    
    private func sortLists() {
        lists.sort { $0.updated > $1.updated }
    }
    
    func syncToWatch() {
        sync.updateLists(lists: Array(lists.prefix(20)))
    }
    
    func sendRefresh() {
        sync.sendRefresh()
    }
    
    func sendRefreshWithRetry() {
        refreshRetryCount = 0
        didReceiveLists = false
        attemptRefresh()
    }
    
    private func attemptRefresh() {
        sendRefresh()
        refreshRetryCount += 1
        refreshRetryTimer?.invalidate()
        refreshRetryTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.lists.isEmpty && !self.didReceiveLists && self.refreshRetryCount < self.maxRefreshRetries {
                self.attemptRefresh()
            }
        }
    }
    
    func delete(at indexSet: IndexSet) {
        for index in indexSet.reversed() {
            let toRemove = lists.remove(at: index)
            commitDelete(list: toRemove)
        }
        syncToWatch()
    }
    
    func commitDelete(list: Checklist) {
        
    }

//MARK: WatchSyncDelegate
    func watchSync(_ watchSync: WatchSync, updated list: Checklist) {
        self.watchSync(watchSync, updated: [list])
    }
    
    func watchSync(_ watchSync: WatchSync, updated lists: [Checklist]) {
        DispatchQueue.main.async {
            lists.forEach { list in
                if let index = self.lists.firstIndex(where: { $0.id == list.id }) {
                    self.lists[index] = list
                } else {
                    self.lists.append(list)
                }
            }
            self.sortLists()
            self.didReceiveLists = true
            self.refreshRetryTimer?.invalidate()
        }
    }
    
    func watchSync(_ watchSync: WatchSync, deleteListWithId id: String) {
        DispatchQueue.main.async {
            if let index = self.lists.firstIndex(where: { $0.id == id }) {
                let toDelete = self.lists.remove(at: index)
                self.commitDelete(list: toDelete)
            }
        }
    }
    
    func watchSyncSentRefresh(_ watchSync: WatchSync) {
        self.sendRefreshWithRetry()
    }
    
    func watchSyncActivated(_ watchSync: WatchSync) {
#if os(iOS)
        self.syncToWatch()
#else
        if self.lists.isEmpty {
            self.sendRefreshWithRetry()
        }
#endif
    }

//MARK: ChecklistViewModelDelegate
    func listDidUpdate(_ checklist: Checklist) {
        if let index = lists.firstIndex(where: { $0.id == checklist.id }) {
            lists[index] = checklist
        } else {
            lists.append(checklist)
            sortLists()
        }
        self.syncToWatch()
    }
}
