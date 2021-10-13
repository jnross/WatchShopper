//
//  ListData.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

struct Checklist: Codable, Identifiable, Equatable {
    struct Item: Codable, Identifiable, Equatable {
        var id: Int
        var title: String
        var checked: Bool
    }
    
    var id = UUID()
    var title: String
    var updated: Date
    var items: [Item]
}

extension Checklist {
    mutating func toggle(item: Checklist.Item) {
        guard let index = items.firstIndex(where: { item.id == $0.id })
            else { return }
        items[index].checked.toggle()
    }
    
    //Sort list items, sending completed/checked items to the bottom.
    mutating func sortCheckedToBottom() {
        items.sort { a, b in
            if a.checked && b.checked == false {
                return false
            } else if b.checked && a.checked == false {
                return true
            } else {
                return a.id < b.id
            }
        }
    }
}

extension Checklist: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(title)(\(id)) @ \(updated):\n"
            + items.map( { ($0.checked ? "✅ " : "") + $0.title } ).joined(separator: "\n")
    }
}
