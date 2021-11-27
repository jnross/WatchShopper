//
//  ContentView.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

struct ListsView: View {
    let formatter: DateFormatter
    init(listsViewModel: ListsViewModel) {
        self.listsViewModel = listsViewModel
        self.formatter = DateFormatter()
        formatter.dateStyle = .medium
    }
    
    @ObservedObject
    var listsViewModel: ListsViewModel
    var body: some View {
        List(listsViewModel.lists) { checklist in
            NavigationLink(destination: ChecklistView(checklistViewModel: ChecklistViewModel(checklist: checklist, delegate: listsViewModel))) {
                VStack(alignment: .leading) {
                    Text(checklist.title)
                        .font(.headline)
                    Text(checklist.updated, formatter: formatter)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
            }
        }
        .navigationTitle("Lists")
        .toolbar {
            Button {
                listsViewModel.saveAll()
            } label: {
                Text("Save")
            }

        }
    }
}

struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        let listsViewModel = ListsViewModel(lists: generateListData())
        NavigationView {
            ListsView(listsViewModel: listsViewModel)
        }
    }
}
