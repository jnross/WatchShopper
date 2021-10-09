//
//  ListsView.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

struct ListsView: View {
    let formatter: DateFormatter
    init(lists: [ChecklistViewModel]) {
        self.lists = lists
        self.formatter = DateFormatter()
        formatter.dateStyle = .medium
    }
    
    var lists: [ChecklistViewModel]
    var body: some View {
        List(lists) { checklist in
            NavigationLink(destination: ChecklistView(checklist: checklist)) {
                VStack(alignment: .leading) {
                    Text(checklist.summary.name)
                        .font(.headline)
                    Text(checklist.summary.updated, formatter: formatter)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
            }
        }
        .navigationTitle("Lists")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.defaultMinListRowHeight, 10)
    }
}

struct ChecklistView: View {
    var checklist: ChecklistViewModel
    var body: some View {
        List(checklist.items) { item in
            let image = Image(systemName: "checkmark")
                .foregroundColor(Color.green)
            Button(action: {
                print("Hello!")
                _ = image.hidden()
            }) {
                HStack {
                    
                    if !item.checked {
                        image
                    } else {
                        image
                    }
                    Text(item.title)
                }
            }
        }
        .navigationTitle(checklist.summary.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.defaultMinListRowHeight, 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let summary = ChecklistSummaryViewModel(name: "Sat List", updated: .now)
        let item1 = ChecklistItemViewModel(title: "chix thighs", checked: false, itemId: 1)
        let item2 = ChecklistItemViewModel(title: "oranges", checked: true, itemId: 2)
        let checklist = ChecklistViewModel(summary: summary, items: [item1, item2])
        NavigationView {
            ListsView(lists: [checklist])
        }
        NavigationView {
            ChecklistView(checklist: checklist)
        }
    }
}
