//
//  ListsViewModel.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import Foundation

struct ChecklistSummaryViewModel: Identifiable {
    let id = UUID()
    let name: String
    let updated: Date
}

struct ChecklistItemViewModel: Identifiable {
    let id = UUID()
    let title: String
    var checked: Bool
    let itemId: Int
}

struct ChecklistViewModel: Identifiable {
    let id = UUID()
    let summary: ChecklistSummaryViewModel
    let items: [ChecklistItemViewModel]
}
