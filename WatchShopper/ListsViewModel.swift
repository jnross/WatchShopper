//
//  ListsViewModel.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

/// Delegate protocol for platform-specific watch sync and persistence behavior
protocol ListsViewModelDelegate {
    /// Called when a refresh request is received from the counterpart device
    func didReceiveRefreshRequest(listsViewModel: ListsViewModel, from watchSync: WatchSync)

    /// Called when the WatchConnectivity session becomes activated
    func didActivate(listsViewModel: ListsViewModel, watchSync: WatchSync)

    /// Called when a list is updated and needs to be persisted
    func didUpdateList(_ checklist: Checklist, in listsViewModel: ListsViewModel)

    /// Called when a list needs to be deleted from persistent storage
    func didDeleteList(_ checklist: Checklist, in listsViewModel: ListsViewModel)
}

class ListsViewModel: ObservableObject, WatchSyncDelegate, ChecklistViewModelDelegate {
    @Published var lists: [Checklist]
    private let sync = WatchSync()
    private let logger = Logger(tag: "ListsViewModel")
    private let syncBehaviorDelegate: ListsViewModelDelegate

    // Retry logic
    private var refreshRetryCount = 0
    private let maxRefreshRetries = 3
    private var refreshRetryTimer: Timer?
    private var didReceiveLists = false

    init(lists: [Checklist], syncBehaviorDelegate: ListsViewModelDelegate) {
        self.lists = lists
        self.syncBehaviorDelegate = syncBehaviorDelegate
        sync.delegate = self
        sortLists()
        logger.info("ListsViewModel init: starting with \(lists.count) lists")
    }
    
    private func sortLists() {
        lists.sort { $0.updated > $1.updated }
    }
    
    // MARK: - Public methods for delegates

    func syncToWatch() {
        let listCount = lists.count
        let syncCount = min(listCount, 20)
        logger.info("syncToWatch: sending \(syncCount) of \(listCount) lists")
        sync.updateLists(lists: Array(lists.prefix(20)))
    }
    
    func sendRefresh() {
        logger.info("sendRefresh: sending refresh message")
        sync.sendRefresh()
    }
    
    func sendRefreshWithRetry() {
        logger.info("sendRefreshWithRetry: starting retry sequence")
        refreshRetryCount = 0
        didReceiveLists = false
        attemptRefresh()
    }

    private func attemptRefresh() {
        logger.info("attemptRefresh: attempt #\(refreshRetryCount + 1) of \(maxRefreshRetries)")
        sendRefresh()
        refreshRetryCount += 1
        refreshRetryTimer?.invalidate()
        refreshRetryTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.lists.isEmpty && !self.didReceiveLists && self.refreshRetryCount < self.maxRefreshRetries {
                self.logger.info("attemptRefresh: retrying (lists empty: \(self.lists.isEmpty), didReceive: \(self.didReceiveLists))")
                self.attemptRefresh()
            } else {
                self.logger.info("attemptRefresh: stopping retries (lists: \(self.lists.count), didReceive: \(self.didReceiveLists), attempts: \(self.refreshRetryCount))")
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
        syncBehaviorDelegate.didDeleteList(list, in: self)
    }

//MARK: WatchSyncDelegate
    func watchSync(_ watchSync: WatchSync, updated list: Checklist) {
        self.watchSync(watchSync, updated: [list])
    }
    
    func watchSync(_ watchSync: WatchSync, updated lists: [Checklist]) {
        logger.info("watchSync: received \(lists.count) lists")
        DispatchQueue.main.async {
            lists.forEach { list in
                if let index = self.lists.firstIndex(where: { $0.id == list.id }) {
                    // Strictly newer only, so a stale or echoed copy can't revert a local edit.
                    guard list.updated > self.lists[index].updated else { return }
                    self.lists[index] = list
                    self.syncBehaviorDelegate.didUpdateList(list, in: self)
                } else {
                    // Not persisted: deletes aren't synced, so unknown lists may be ones deleted here.
                    self.lists.append(list)
                }
            }
            self.sortLists()
            self.logger.info("watchSync: now have \(self.lists.count) total lists")
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
    
    // Platform-specific behavior - delegated to platform-specific implementations
    func watchSyncSentRefresh(_ watchSync: WatchSync) {
        syncBehaviorDelegate.didReceiveRefreshRequest(listsViewModel: self, from: watchSync)
    }
    
    func watchSyncActivated(_ watchSync: WatchSync) {
        syncBehaviorDelegate.didActivate(listsViewModel: self, watchSync: watchSync)
    }

//MARK: ChecklistViewModelDelegate
    func listDidUpdate(_ checklist: Checklist) {
        var checklist = checklist
        if let index = lists.firstIndex(where: { $0.id == checklist.id }) {
            // Equality ignores `updated`; skip no-op saves (e.g. on view disappear) so they don't win sync conflicts.
            guard checklist != lists[index] else { return }
            checklist.updated = .now
            lists[index] = checklist
        } else {
            checklist.updated = .now
            lists.append(checklist)
            sortLists()
        }
        syncBehaviorDelegate.didUpdateList(checklist, in: self)
        self.syncToWatch()
    }
}

// Simple no-op delegate for previews
class PreviewWatchSyncBehavior: ListsViewModelDelegate {
    func didReceiveRefreshRequest(listsViewModel: ListsViewModel, from watchSync: WatchSync) {}
    func didActivate(listsViewModel: ListsViewModel, watchSync: WatchSync) {}
    func didUpdateList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {}
    func didDeleteList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {}
}
