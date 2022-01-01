//
//  ContentView.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/7/21.
//

import SwiftUI

struct ListsView: View {
    let formatter: DateFormatter
    init(listsViewModel: PersistingListsViewModel) {
        self.listsViewModel = listsViewModel
        self.formatter = DateFormatter()
        formatter.dateStyle = .medium
    }
    
    @ObservedObject
    var listsViewModel: PersistingListsViewModel
    var body: some View {
        List(listsViewModel.lists) { checklist in
            NavigationLink(destination: NavigationLazyView(ChecklistView(checklistViewModel: ChecklistViewModel(checklist: checklist, delegate: listsViewModel))))
            {
                VStack(alignment: .leading) {
                    Text(checklist.title)
                        .font(.headline)
                    Text(checklist.updated, formatter: formatter)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
            }
        }
        .navigationBarTitle("Lists", displayMode: .inline)
        .toolbar {
            NavigationLink(destination: NavigationLazyView(ChecklistView(checklistViewModel: ChecklistViewModel(checklist: listsViewModel.createNewCheckList(), delegate: listsViewModel))))
            {
                Image(systemName: "plus")
            }
            Button {
                listsViewModel.syncToWatch()
            } label: {
                Image(systemName: "applewatch")
            }
        }
    }
}

struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        let listsViewModel = PersistingListsViewModel(lists: generateListData())
        NavigationView {
            ListsView(listsViewModel: listsViewModel)
        }
    }
}
