//
//  ListData.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

struct Checklist: Codable, Identifiable, Equatable {
    struct Item: Codable, Identifiable, Equatable {
        var id:String = UUID().uuidString
        var title: String
        var checked: Bool
    }
    
    var id: String = UUID().uuidString
    var title: String
    var updated: Date
    var items: [Item] = []

    static func ==(lhs: Checklist, rhs: Checklist) -> Bool {
        // Ignore `updated` `Date` when comparing for equality.  If everything else is equal, the checklists are equal.
        return lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.items == rhs.items
        
    }
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
                return false
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
