//
//  PhoneSyncBehavior.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/25/25.
//

import Foundation

/// iOS-specific watch sync behavior: responds to watch requests by sending data and persists changes
class PhoneSyncBehavior: ListsViewModelDelegate {
    private let logger = Logger(tag: "PhoneWatchSyncBehavior")
    private let persistence: Persistence

    init(persistence: Persistence) {
        self.persistence = persistence
    }

    func didReceiveRefreshRequest(listsViewModel: ListsViewModel, from watchSync: WatchSync) {
        // iPhone receives refresh request from watch - send the lists data
        logger.info("didReceiveRefreshRequest: received refresh request, sending lists")
        listsViewModel.syncToWatch()
    }

    func didActivate(listsViewModel: ListsViewModel, watchSync: WatchSync) {
        // iPhone sends data when watch connection activates
        logger.info("didActivate: connection activated, syncing to watch")
        listsViewModel.syncToWatch()
    }

    func didUpdateList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {
        logger.info("didUpdateList: persisting list '\(checklist.title)'")
        persistence.save(checklist)
    }

    func didDeleteList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {
        logger.info("didDeleteList: deleting list '\(checklist.title)'")
        persistence.delete(checklist)
    }
}
