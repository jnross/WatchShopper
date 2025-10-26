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
        List {
            Section {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $newItemText)
                        .frame(minHeight: 20, maxHeight: 40)
                        .focused($focusedField, equals: .newItem)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: newItemText) { newValue in
                            if newValue.contains("\n") {
                                let trimmedText = newValue.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespaces)
                                if !trimmedText.isEmpty {
                                    checklistViewModel.addItem(trimmedText)
                                } else {
                                    focusedField = nil
                                }
                                newItemText = ""
                            }
                        }
                    if newItemText.isEmpty {
                        Text("Add Item")
                            .foregroundColor(Color(uiColor: .placeholderText))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
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
        }
        
    }
}

enum FocusedField: Hashable {
    case listTitle, newItem
}

struct ChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview uses a no-op delegate
        let listsViewModel = ListsViewModel(lists: generateListData(), syncBehaviorDelegate: PreviewWatchSyncBehavior())
        let checklistViewModel = ChecklistViewModel(checklist: listsViewModel.lists.first!)
        NavigationView {
            ChecklistView(checklistViewModel: checklistViewModel)
            ListsView(listsViewModel: listsViewModel)
        }
    }
}
