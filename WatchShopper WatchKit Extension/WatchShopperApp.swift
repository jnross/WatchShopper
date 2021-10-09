//
//  WatchShopperApp.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

@main
struct WatchShopperApp: App {
    
    var lists: [Checklist] = generateListData()
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                let listsViewModel = ListsViewModel(lists: lists)
                ListsView(listsViewModel: listsViewModel)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
