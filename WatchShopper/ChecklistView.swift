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
    
    @State private var newItemText: String = ""
    @FocusState private var isNewItemFieldFocused: Bool
    
    var body: some View {
        let newItemField = TextField("Add Item", text: $newItemText)
        List {
            Section {
                newItemField
                    .autocapitalization(.none)
                    .focused($isNewItemFieldFocused)
                    .onSubmit {
                        // If the user hits "Return" with an empty field, they probably just want to hide the keyboard.
                        if newItemText.isEmpty == false {
                            checklistViewModel.addItem(newItemText)
                            newItemText = ""
                            isNewItemFieldFocused = true
                        }
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
        // Remove focus from new item field and hide keyboard when the view is scrolled.
        .simultaneousGesture(DragGesture().onChanged({ _ in
            isNewItemFieldFocused = false
        }))
    }
}

struct ChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        let listsViewModel = PersistingListsViewModel(lists: generateListData())
        let checklistViewModel = ChecklistViewModel(checklist: listsViewModel.lists.first!)
        NavigationView {
            ChecklistView(checklistViewModel: checklistViewModel)
            ListsView(listsViewModel: listsViewModel)
        }
    }
}
