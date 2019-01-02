//
//  ChecklistTest.swift
//  WatchShopperTests
//
//  Created by Joseph Ross on 1/1/19.
//  Copyright © 2019 Easy Street 3. All rights reserved.
//

import XCTest

class ChecklistTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitWithNote() {
        let note = EDAMNote()
        note.guid = "aGuid"
        note.title = "Hamburger List"
        note.updated = NSNumber(value: NSDate().edamTimestamp)
        note.content = """
                       <?xml version="1.0" encoding="UTF-8"?>
                       <!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
                       <en-note><div>ketchup</div><div>mustard</div><div>pickles</div>
                       <div><span style="text-decoration: line-through;">beef</span></div>
                       <div><span>w sauce</span></div><div>buns</div><div>cheese</div>
                       <div>mayo</div><div>toms</div><div>lettuce</div><div>onion</div></en-note>
                       """
        let checklist = Checklist(note: note)
        XCTAssertEqual(checklist.name, note.title, "Names should match")
        XCTAssertEqual(checklist.guid, note.guid, "Guids should match")
        XCTAssertEqual(checklist.items.count, 11, "Expecting 11 items")
        
        let checkedCount = checklist.items.filter({ $0.checked }).count
        XCTAssertEqual(checkedCount, 1, "Expecting 1 checked item")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
