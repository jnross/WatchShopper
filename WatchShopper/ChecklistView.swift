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
    @FocusState var focusedField: FocusedField?
    
    var body: some View {
        let newItemField = TextField("Add Item", text: $newItemText)
        List {
            Section {
                newItemField
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .newItem)
                    .onSubmit {
                        // If the user hits "Return" with an empty field, they probably just want to hide the keyboard.
                        if newItemText.isEmpty == false {
                            checklistViewModel.addItem(newItemText)
                            newItemText = ""
                            focusedField = .newItem
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
        .listStyle(.plain)
        .animation(.default, value: checklistViewModel.checklist)
        .onDisappear {
            checklistViewModel.saveChecklist()
        }
        // Remove focus from new item field and hide keyboard when the view is scrolled.
        .simultaneousGesture(DragGesture().onChanged({ _ in
            focusedField = nil
        }))
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField(checklistViewModel.checklist.title, text: $checklistViewModel.checklist.title, prompt: Text("List Title"))
                    .focused($focusedField, equals: .listTitle)
                    .font(Font.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            if checklistViewModel.checklist.title.isEmpty {
                                focusedField = .listTitle
                            }
                        }
                    }
                    .onSubmit {
                        checklistViewModel.setTitle(checklistViewModel.checklist.title)
                        focusedField = .newItem
                    }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "plus").colorMultiply(.clear).tint(.clear)
            }
        }
        
    }
}

enum FocusedField: Hashable {
    case listTitle, newItem
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
