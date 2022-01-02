//
//  PersistenceTests.swift
//  WatchShopperTests
//
//  Created by Joseph Ross on 12/29/21.
//

import XCTest
@testable import WatchShopper

class PersistenceTests: XCTestCase {
    
    let persistence = Persistence(dbName: "tests")!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        persistence.erase()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateEmptyList() throws {
        let checklist = persistence.newChecklist(title: "Test 1")
        
        persistence.save(checklist)
        
        XCTAssertEqual(persistence.countChecklists(), 1)
    }

    func testCreateSmallList() throws {
        var checklist = persistence.newChecklist(title: "Three Veggies")
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        
        persistence.save(checklist)
        
        XCTAssertEqual(persistence.countChecklists(), 1)
        XCTAssertEqual(persistence.countItems(), 3)
        XCTAssertEqual(persistence.countChecklistItems(), 3)
    }
    
    func testCreateOverlappingLists() throws {
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
    
    func testRetrieveEmptyList() throws {
        let checklist = persistence.newChecklist(title: "Test 1")
        persistence.save(checklist)
        
        let checklists = persistence.allChecklists()
        XCTAssertEqual(checklist, checklists.first!)
    }
    
    func testRetrieveSmallList() throws {
        var checklist = persistence.newChecklist(title: "Three Veggies")
    
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        
        persistence.save(checklist)
        
        let checklists = persistence.allChecklists()
        XCTAssertEqual(checklist, checklists.first!)
    }
    
    func testRetrieveOverlappingLists() throws {
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
        
        let checklists = persistence.allChecklists()
        XCTAssertEqual([checklist, checklist2], checklists)
    }
    
    func testDeletingItemsFromSmallList() throws {
        var checklist = persistence.newChecklist(title: "Spag Sauce")
    
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        checklist.items.append(persistence.item(withTitle: "tomatoes"))
        checklist.items.append(persistence.item(withTitle: "olive oil"))
        
        persistence.save(checklist)
        
        XCTAssertEqual(persistence.countChecklists(), 1)
        XCTAssertEqual(persistence.countItems(), 5)
        XCTAssertEqual(persistence.countChecklistItems(), 5)
        
        checklist.items.removeLast()
        checklist.items.removeLast()
        
        persistence.save(checklist)
        
        let checklists = persistence.allChecklists()
        XCTAssertEqual(checklist, checklists.first!)
        
        // We expect all five items to remain in the DB, but the linking table will only have three links.
        XCTAssertEqual(persistence.countItems(), 5)
        XCTAssertEqual(persistence.countChecklistItems(), 3)
    }
    
    func testLoadingListById() throws {
        var checklist = persistence.newChecklist(title: "Spag Sauce")
    
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        checklist.items.append(persistence.item(withTitle: "tomatoes"))
        checklist.items.append(persistence.item(withTitle: "olive oil"))
        
        persistence.save(checklist)
        
        checklist.items.removeLast()
        checklist.items.removeLast()
        
        persistence.save(checklist)
        
        let loadedChecklist = persistence.checklist(forId: checklist.id)
        XCTAssertEqual(checklist, loadedChecklist)
    }
    
    func testAutocompleteResults() throws {
        var checklist = persistence.newChecklist(title: "Spag Sauce")
    
        checklist.items.append(persistence.item(withTitle: "carrots"))
        checklist.items.append(persistence.item(withTitle: "celery"))
        checklist.items.append(persistence.item(withTitle: "onions"))
        checklist.items.append(persistence.item(withTitle: "tomatoes"))
        checklist.items.append(persistence.item(withTitle: "olive oil"))
        
        let autocompleteResults = persistence.autocompleteMatches(forPrefix: "c")
        XCTAssertEqual(autocompleteResults, ["carrots", "celery"])
    }
    
    func testDeleteList() throws {
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
        
        persistence.delete(checklist)
        
        XCTAssertEqual(persistence.countChecklists(), 1)
        XCTAssertEqual(persistence.countItems(), 4)
        XCTAssertEqual(persistence.countChecklistItems(), 3)
    }
    
}
