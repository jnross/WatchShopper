//
//  WatchShopperApp.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

@main
struct WatchShopperApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ListsView(listSummaries: [ChecklistSummaryViewModel(name: "Sat List", updated: ISO8601DateFormatter().date(from: "2021-10-02T21:45:30Z")!)])
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
