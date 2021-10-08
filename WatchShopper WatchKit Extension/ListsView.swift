//
//  ListsView.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

struct ListsView: View {
    let formatter: DateFormatter
    init(listSummaries: [ChecklistSummaryViewModel]) {
        self.listSummaries = listSummaries
        self.formatter = DateFormatter()
        formatter.dateStyle = .medium
    }
    
    var listSummaries: [ChecklistSummaryViewModel]
    var body: some View {
        List(listSummaries) { summary in
            VStack(alignment: .leading) {
                Text(summary.name)
                    .font(.headline)
                Text(summary.updated, formatter: formatter)
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
        }
        .navigationTitle("Lists")
        .environment(\.defaultMinListRowHeight, 10)
    }
}

struct ChecklistView: View {
    var checklist: ChecklistViewModel
    var body: some View {
        List(checklist.items) { item in
            HStack {
                let image = Image(systemName: "checkmark")
                    .foregroundColor(Color.green)
                if !item.checked {
                    image.hidden()
                } else {
                    image
                }
                Text(item.title)
            }
        }
        .navigationTitle(checklist.summary.name)
        .environment(\.defaultMinListRowHeight, 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let summary = ChecklistSummaryViewModel(name: "Sat List", updated: .now)
        let item1 = ChecklistItemViewModel(title: "chix thighs", checked: false, itemId: 1)
        let item2 = ChecklistItemViewModel(title: "oranges", checked: true, itemId: 2)
        NavigationView {
            ListsView(listSummaries: [summary])
        }
        NavigationView {
            ChecklistView(checklist: ChecklistViewModel(summary: summary,
                                                        items: [item1, item2]))
        }
    }
}
