//
//  WatchShopperApp.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

@main
struct WatchShopperApp: App {

    @StateObject private var listsViewModel = ListsViewModel(lists: [])

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ListsView(listsViewModel: listsViewModel)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
