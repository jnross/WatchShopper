//
//  WatchShopperApp.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

@main
struct WatchShopperApp: App {
    var lists: [Checklist] = generateListData()
    var body: some Scene {
        WindowGroup {
            NavigationView {
                let listsViewModel = ListsViewModel(lists: lists)
                ListsView(listsViewModel: listsViewModel)
            }
        }
    }
}
