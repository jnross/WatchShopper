//
//  ChecklistView.swift
//  WatchShopper
//
//  Created by Joseph Ross on 11/27/21.
//

import SwiftUI

struct ChecklistView: View {
    @ObservedObject
    var checklistViewModel: ChecklistViewModel
    
    @State var newItemText: String = ""
    var body: some View {
        List {
            Section {
                TextField("Add Item", text: $newItemText)
                    .onSubmit {
                        checklistViewModel.addItem(newItemText)
                        newItemText = ""
                    }
            }
            Section {
                ForEach(checklistViewModel.checklist.items) { item in
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
                }.onDelete { indexSet in
                    checklistViewModel.delete(at: indexSet)
                }
            }
        }
        .animation(.default, value: checklistViewModel.checklist)
        .navigationTitle(checklistViewModel.checklist.title)
        .onDisappear {
            checklistViewModel.saveChecklist()
        }
    }
}

struct ChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        let listsViewModel = ListsViewModel(lists: generateListData())
        let checklistViewModel = ChecklistViewModel(checklist: listsViewModel.lists.first!)
        NavigationView {
            ChecklistView(checklistViewModel: checklistViewModel)
            ListsView(listsViewModel: listsViewModel)
        }
    }
}
