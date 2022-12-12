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
        self.newChecklistViewModel = ChecklistViewModel(checklist: Checklist(title: "New"), delegate: nil)
        newChecklistViewModel.delegate = listsViewModel
    }
    
    @ObservedObject
    var listsViewModel: PersistingListsViewModel
    
    @ObservedObject
    var newChecklistViewModel: ChecklistViewModel
    var body: some View {
        List {
            ForEach(listsViewModel.lists) { checklist in
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
            }.onDelete { indexSet in
                listsViewModel.delete(at: indexSet)
            }
        }
        .navigationBarTitle("Lists", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    listsViewModel.syncToWatch()
                } label: {
                    Image(systemName: "applewatch")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ChecklistView(checklistViewModel: newChecklistViewModel))
                {
                    Image(systemName: "plus")
                }.simultaneousGesture(TapGesture().onEnded({
                    newChecklistViewModel.checklist = Checklist(title: "")
                }))
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
