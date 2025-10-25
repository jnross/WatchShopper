//
//  WatchSyncBehavior.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/25/25.
//

import Foundation

/// watchOS-specific watch sync behavior: requests data from iPhone (no persistence)
class WatchSyncBehavior: ListsViewModelDelegate {
    private let logger = Logger(tag: "WatchAppSyncBehavior")

    func didReceiveRefreshRequest(listsViewModel: ListsViewModel, from watchSync: WatchSync) {
        // Watch should not receive refresh messages - only send them
        // If we receive one unexpectedly, log a warning
        logger.info("didReceiveRefreshRequest: unexpectedly received refresh on watch (ignoring)")
    }

    func didActivate(listsViewModel: ListsViewModel, watchSync: WatchSync) {
        // Watch requests data when connection activates (if needed)
        logger.info("didActivate: connection activated, requesting data if empty (lists: \(listsViewModel.lists.count))")
        if listsViewModel.lists.isEmpty {
            listsViewModel.sendRefreshWithRetry()
        }
    }

    func didUpdateList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {
        // Watch doesn't persist - all data comes from iPhone
    }

    func didDeleteList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {
        // Watch doesn't persist - all data comes from iPhone
    }
}
