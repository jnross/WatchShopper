//
//  UserDefaultsPersistence.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/10/21.
//

import Foundation
import UIKit
import GRDB

extension Checklist: FetchableRecord, PersistableRecord {}
extension Checklist.Item: FetchableRecord, MutablePersistableRecord {}

class Persistence {
    private let dbq: DatabaseQueue
    
    init?() {
        do {
            var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            url.appendPathComponent("persistence.sqlite")
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
                t.primaryKey(["id"])
                t.column("title", .text)
                t.column("updated", .datetime)
            })
            try db.create(table: "item", body: { t in
                t.column("id", .text)
                t.primaryKey(["id"])
                t.column("title", .text)
            })
            try db.create(table: "checklist_item", body: { t in
                t.column("checklist_id", .text).references("checklist")
                t.column("item_id", .text).references("item")
                t.primaryKey(["checklist_id", "item_id"], onConflict: .replace)
                t.column("checked", .boolean)
            })
        }
        return migrator
    }
    
    func save(_ checklist: Checklist) {
        
    }
    
    func save(_ item : Checklist.Item) {
        
    }
    
    func createChecklist(title: String) -> Checklist {
        let checklist = Checklist(title: title, updated: .now, items: [])
        do {
            try dbq.inDatabase { db in
                try checklist.insert(db)
            }
        } catch {
            NSLog("Failed to insert new checklist: \(error)")
        }
        return checklist
    }
    
    func createItem(title: String, checked: Bool = false) -> Checklist.Item {
        var item = Checklist.Item(title: title, checked: checked)
        do {
            try dbq.inDatabase { db in
                try item.insert(db)
            }
        } catch {
            NSLog("Failed to insert new checklist: \(error)")
        }
        return item
    }
}
