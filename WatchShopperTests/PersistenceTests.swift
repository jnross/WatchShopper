//
//  PersistenceTests.swift
//  WatchShopperTests
//
//  Created by Joseph Ross on 12/29/21.
//

import XCTest
@testable import WatchShopper

class PersistenceTests: XCTestCase {
    
    let persistence = Persistence()!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        persistence.erase()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEmptyList() throws {
        var checklist = persistence.newChecklist(title: "Test 1")
        
        persistence.save(checklist)
        
        XCTAssertEqual(persistence.countChecklists(), 1)
    }

    func testSmallList() throws {
        var checklist = persistence.newChecklist(title: "Three Veggies")
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        
        persistence.save(checklist)
        
        XCTAssertEqual(persistence.countChecklists(), 1)
        XCTAssertEqual(persistence.countItems(), 3)
        XCTAssertEqual(persistence.countChecklistItems(), 3)
    }
    
    func testOverlappingLists() throws {
        var checklist = persistence.newChecklist(title: "Three Veggies")
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        
        var checklist2 = persistence.newChecklist(title: "Spag Veggies")
        checklist2.items.append(persistence.item(withTitle: "tomatoes"))
        checklist2.items.append(persistence.item(withTitle: "carrots"))
        checklist2.items.append(persistence.item(withTitle: "onions"))
        
        persistence.save(checklist)
        persistence.save(checklist2)
        
        XCTAssertEqual(persistence.countChecklists(), 2)
        XCTAssertEqual(persistence.countItems(), 4)
        XCTAssertEqual(persistence.countChecklistItems(), 6)
    }
}
