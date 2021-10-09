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
                let listModels = lists.map { list in
                    ChecklistViewModel(summary: ChecklistSummaryViewModel(name: list.title, updated: list.updated),
                                       items: list.items.map { ChecklistItemViewModel(title: $0.title, checked: $0.checked, itemId: $0.id) })
                }
                ListsView(lists: listModels)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
