//
//  GRDBSandboxTests.swift
//  WatchShopperTests
//
//  Created by Joseph Ross on 12/29/21.
//

import XCTest
import GRDB
@testable import WatchShopper

class GRDBSandboxTests: XCTestCase {
    
    var dbq = DatabaseQueue()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent("persistence.sqlite")
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace(options: .profile) { event in
                // Prints all SQL statements with their duration
                print(event)
                
                // Access to detailed profiling information
                if case let .profile(statement, duration) = event, duration > 0.5 {
                    print("Slow query: \(statement.sql)")
                }
            }
        }
        dbq = try DatabaseQueue(path: url.path, configuration: config)
        try dbq.erase()
        try GRDBSandboxTests.createMigrator().migrate(dbq)
    }
    
    private static func createMigrator() -> DatabaseMigrator {
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

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateAndFetchListRecords() throws {
        let listRecord = ChecklistRecord(id: UUID().uuidString, title: "List 1", updated: .now)
        let itemRecord = ItemRecord(title: "carrots")
        let checklistItemRecord = ChecklistItemRecord.init(checked: false, checklistId: listRecord.id, itemId: itemRecord.id)
        
        try dbq.inDatabase { db in
            try listRecord.insert(db)
            try itemRecord.insert(db)
            try checklistItemRecord.insert(db)
        }
        
        
        
        let checklist = try dbq.read({ db in
            return try ChecklistRecord.all().fetchOne(db)
        })!
        
        print(checklist)
        
        let completeItems = try dbq.read({ db -> [CompleteChecklistItem] in
            let request = checklist.checklistItems.including(required: ChecklistItemRecord.item)
            
            return try CompleteChecklistItem.fetchAll(db, request)
        })
        
        print(completeItems)
    }
}
