//
//  UserDefaultsPersistence.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/10/21.
//

import Foundation
import UIKit
import GRDB

struct ChecklistRecord: FetchableRecord, PersistableRecord, Codable, Identifiable {
    var id: String
    var title: String
    var updated: Date = .now
    
    static let databaseTableName = "checklist"
    
    static let checkListItems = hasMany(ChecklistItemRecord.self)
    
    var checklistItems: QueryInterfaceRequest<ChecklistItemRecord> {
        request(for: ChecklistRecord.checkListItems)
    }
}


struct ItemRecord: FetchableRecord, PersistableRecord, Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    
    static let databaseTableName = "item"
    
    static let checklists = hasMany(ChecklistRecord.self, through: checklistItems, using: ChecklistItemRecord.checklist)
    static let checklistItems = hasMany(ChecklistItemRecord.self)
    
    var checklists: QueryInterfaceRequest<ChecklistRecord> {
        request(for: ItemRecord.checklists)
    }
}

struct ChecklistItemRecord: FetchableRecord, PersistableRecord, Codable {
    var checked: Bool = false
    var checklistId: String
    var itemId: String
    
    static let databaseTableName = "checklistItem"
    
    static let checklist = belongsTo(ChecklistRecord.self)
    static let item = belongsTo(ItemRecord.self)
    
    var checklist: QueryInterfaceRequest<ChecklistRecord> {
        request(for: ChecklistItemRecord.checklist)
    }
    
    var item: QueryInterfaceRequest<ItemRecord> {
        request(for: ChecklistItemRecord.item)
    }
    
}

struct CompleteChecklistItem: FetchableRecord, Decodable {
    var checklistItem: ChecklistItemRecord
    var item: ItemRecord
}

class Persistence {
    private let dbq: DatabaseQueue
    
    init?(dbName: String? = nil) {
        let dbName = dbName ?? "persistence"
        
        do {
            var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            url.appendPathComponent("\(dbName).sqlite")
            NSLog("DB URL: \(url)")
            dbq = try DatabaseQueue(path: url.path)
            try createMigrator().migrate(dbq)
        } catch {
            NSLog("Failed to setup database for persistence work: \(error)")
            return nil
        }
    }
    
    private func createMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
#if DEBUG
        // This setting makes it easier to make DB changes without continually tripping on an inconsistent DB file.
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        migrator.registerMigration("v1") { db in
            try db.create(table: "checklist", body: { t in
                t.column("id", .text)
                t.primaryKey(["id"], onConflict: .replace)
                t.column("title", .text)
                t.column("updated", .datetime)
            })
            try db.create(table: "item", body: { t in
                t.column("id", .text)
                t.primaryKey(["id"])
                t.column("title", .text)
            })
            try db.create(table: "checklistItem", body: { t in
                t.column("checklistId", .text)
                    .notNull()
                    .indexed()
                    .references("checklist")
                t.column("itemId", .text)
                    .notNull()
                    .indexed()
                    .references("item")
                t.primaryKey(["checklistId", "itemId"], onConflict: .replace)
                t.column("checked", .boolean)
            })
        }
        return migrator
    }
    
    func save(_ checklist: Checklist) {
        var checklistRecord = ChecklistRecord(id: checklist.id, title: checklist.title, updated: checklist.updated)
        // Should we set `.updated` to `.now` here, or trust the existing value?
        checklistRecord.updated = .now
        
        var checklistItemRecords:[ChecklistItemRecord] = []
        for item in checklist.items {
            let resolvedItem = self.item(withTitle: item.title, checked: item.checked)
            checklistItemRecords.append(ChecklistItemRecord(checked: item.checked, checklistId: checklist.id, itemId: resolvedItem.id))
        }
        
        do {
            try dbq.write { db in
                try checklistRecord.insert(db)
                //Clear old item links before writing the new ones:
                try ChecklistItemRecord
                    .filter(Column("checklistId") == checklist.id)
                    .deleteAll(db)
                
                for record in checklistItemRecords {
                    try record.insert(db)
                }
            }
        } catch {
            assertionFailure("Failed to insert new checklist: \(error)")
        }
    }
    
    func save(_ item : Checklist.Item, in checklist: Checklist) {
        let resolvedItem = self.item(withTitle: item.title)
        let checklistItemRecord = ChecklistItemRecord(checked: item.checked, checklistId: checklist.id, itemId: resolvedItem.id)
        
        do {
            try dbq.write { db in
                try checklistItemRecord.insert(db)
            }
        } catch {
            assertionFailure("Failed to save checklistItem: \(error)")
        }
    }
    
    func delete(_ list: Checklist) {
        do {
            try dbq.write({ db in
                try ChecklistItemRecord
                    .filter(Column("checklistId") == list.id)
                    .deleteAll(db)
                try ChecklistRecord.filter(key: list.id).deleteAll(db)
            })
        } catch {
            assertionFailure("Failed to delete checklist with id \(list.id), error: \(error)")
        }
    }
    
    func newChecklist(title: String) -> Checklist {
        let checklist = Checklist(title: title, updated: .now, items: [])
        
        return checklist
    }
    
    func item(withTitle title: String, checked: Bool = false) -> Checklist.Item {
        do {
            let itemRecord = try dbq.read {db in
                return try ItemRecord.filter(Column("title") == title)
                    .fetchOne(db)
            }
            if let itemRecord = itemRecord {
                return Checklist.Item(id: itemRecord.id, title: title, checked: checked)
            } else {
                let itemRecord = ItemRecord(title: title)
                try dbq.write { db in
                    try itemRecord.insert(db)
                }
                return Checklist.Item(id: itemRecord.id, title: title, checked: checked)
            }
        } catch {
            assertionFailure("Failed to insert new checklist: \(error)")
        }
        
        return Checklist.Item(title: title, checked: checked)
    }
    
    func allChecklists() -> [Checklist] {
        var checklists: [Checklist] = []
        do {
            let checklistRecords = try dbq.read { db in
                return try ChecklistRecord.all().fetchAll(db)
            }
                
            for checklistRecord in checklistRecords {
                let checklist = try populateChecklist(from: checklistRecord)
                checklists.append( checklist)
            }
                
        } catch {
            assertionFailure("Failed to load checklists: \(error)")
        }
        return checklists

    }
    
    func checklist(forId id: String) -> Checklist? {
        do {
            let checklistRecord = try dbq.read { db in
                return try ChecklistRecord.filter(key: id).fetchOne(db)
            }
            guard let checklistRecord = checklistRecord else {
                return nil
            }
            return try populateChecklist(from: checklistRecord)

        } catch {
            assertionFailure("Failed to load checklist for id: \(id), error: \(error)")
        }
        return nil
    }
    
    private func populateChecklist(from checklistRecord: ChecklistRecord) throws -> Checklist {
        let request = checklistRecord.checklistItems
            .including(required: ChecklistItemRecord.item)
            .filter(Column("checklistId") == checklistRecord.id)
        
        let completeItems = try dbq.read { db in
            return try CompleteChecklistItem.fetchAll(db, request)
        }
        
        let items = completeItems.map { completeItem in
            return Checklist.Item(id: completeItem.item.id, title: completeItem.item.title, checked: completeItem.checklistItem.checked)
        }
    
        return Checklist(id: checklistRecord.id, title: checklistRecord.title, updated: checklistRecord.updated, items: items)
    }
    
    func autocompleteMatches(forPrefix prefix: String) -> [String] {
        // TODO: determine the practical limit of autocomplete results to return
        let maxAutocompleteResults = 20
        do {
            let itemRecords = try dbq.read { db in
                return try ItemRecord
                    .filter(Column("title").like("\(prefix)%"))
                    .limit(maxAutocompleteResults)
                    .fetchAll(db)
            }
            return itemRecords.map { $0.title }
            
        } catch {
            assertionFailure("Failed to load autocomplete results: \(error)")
        }
        return []
    }
}

// MARK: Persistence Debug Operations - should not be called in a Release build
// TODO: Figure out how to enforce this.

extension Persistence {
    func erase() {
        do {
            try dbq.erase()
            try createMigrator().migrate(dbq)
        } catch {
            assertionFailure("Failed to erase database: \(error)")
        }
    }
    
    func countChecklists() -> Int {
        return try! dbq.read { db in
            return try! ChecklistRecord.fetchCount(db)
        }
    }
    
    func countChecklistItems() -> Int {
        return try! dbq.read { db in
            return try! ChecklistItemRecord.fetchCount(db)
        }
    }
    
    func countItems() -> Int {
        return try! dbq.read { db in
            return try! ItemRecord.fetchCount(db)
        }
    }
}
