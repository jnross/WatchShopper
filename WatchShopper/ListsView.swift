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
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.defaultMinListRowHeight, 10)
    }
}

struct ChecklistView: View {
    @ObservedObject
    var checklistViewModel: ChecklistViewModel
    
    var body: some View {
        List(checklistViewModel.checklist.items) { item in
            let image = Image(systemName: "checkmark")
                .foregroundColor(Color.green)
            Button(action: {
                checklistViewModel.toggleChecked(for: item)
            }) {
                HStack {
                    
                    if !item.checked {
                        image.hidden()
                    } else {
                        image
                    }
                    Text(item.title)
                }
            }
        }
        .animation(.default, value: checklistViewModel.checklist)
        .navigationTitle(checklistViewModel.checklist.title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.defaultMinListRowHeight, 10)
        .onDisappear {
            checklistViewModel.saveChecklist()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let listsViewModel = ListsViewModel(lists: generateListData())
        let checklistViewModel = ChecklistViewModel(checklist: listsViewModel.lists.first!)
        NavigationView {
            ListsView(listsViewModel: listsViewModel)
        }
        NavigationView {
            ChecklistView(checklistViewModel: checklistViewModel)
        }
    }
}
