//
//  WatchShopperApp.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

@main
struct WatchShopperApp: App {
    var persistence: Persistence = Persistence()!
    var lists: [Checklist] = []
    var body: some Scene {
        WindowGroup {
            NavigationView {
                let listsViewModel = PersistingListsViewModel(persistence: persistence)
                ListsView(listsViewModel: listsViewModel)
            }
        }
    }
}
