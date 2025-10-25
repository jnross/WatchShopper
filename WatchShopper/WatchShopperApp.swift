//
//  WatchShopperApp.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

@main
struct WatchShopperApp: App {
    var body: some Scene {
        WindowGroup {
            let persistence = Persistence()!
            let syncBehavior = PhoneSyncBehavior(persistence: persistence)
            let listsViewModel = ListsViewModel(lists: persistence.allChecklists(), syncBehaviorDelegate: syncBehavior)
            NavigationView {
                ListsView(listsViewModel: listsViewModel)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(listsViewModel)
            
        }
    }
}
