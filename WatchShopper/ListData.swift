//
//  ListData.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

struct Checklist {
    struct Item {
        var id: Int
        var title: String
        var checked: Bool
    }
    
    var title: String
    var updated: Date
    var items: [Item]
}
