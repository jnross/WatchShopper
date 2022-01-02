//
//  PersistingListsViewModel.swift
//  WatchShopper
//
//  Created by Joseph Ross on 11/28/21.
//

import Foundation

class PersistingListsViewModel: ListsViewModel {
    private let persistence: Persistence
    
    override init(lists: [Checklist]) {
        self.persistence = Persistence()!
        super.init(lists: lists)
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
        super.init(lists: persistence.allChecklists())
    }
    
    override func listDidUpdate(_ checklist: Checklist) {
        super.listDidUpdate(checklist)
        persistence.save(checklist)
    }
    
    override func commitDelete(list: Checklist) {
        persistence.delete(list)
    }
}
