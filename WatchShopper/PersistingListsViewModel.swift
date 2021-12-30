//
//  PersistingListsViewModel.swift
//  WatchShopper
//
//  Created by Joseph Ross on 11/28/21.
//

import Foundation

class PersistingListsViewModel: ListsViewModel {
    private let persistence = Persistence()!
    
    func createNewCheckList(title:String = "New") -> Checklist {
        let checklist = persistence.newChecklist(title: title)
        return checklist
    }
}
