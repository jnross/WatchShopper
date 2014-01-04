//
//  ESChecklistTest.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ESChecklist.h"

@interface ESChecklistTest : XCTestCase

@end

@implementation ESChecklistTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testInitWithNote
{
    EDAMNote * note = [[EDAMNote alloc] init];
    note.guid = @"aGuid";
    note.title = @"Hamburger List";
    note.content = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
    "<en-note><div>ketchup</div><div>mustard</div><div>pickles</div><div><span style=\"text-decoration: line-through;\">beef</span></div><div><span>w sauce</span></div><div>buns</div><div>cheese</div><div>mayo</div><div>toms</div><div>lettuce</div><div>onion</div></en-note>";
    ESChecklist *checklist = [[ESChecklist alloc] initWithNote:note];
    XCTAssertEqualObjects(checklist.name, note.title, @"Names should match");
    XCTAssertEqualObjects(checklist.guid, note.guid, @"Guids should match");
    XCTAssert(checklist.items.count == 11, @"Expect 11 items");
    
    NSInteger checkedCount = 0;
    for (ESChecklistItem *item in checklist.items) {
        if (item.isChecked) {
            checkedCount++;
        }
    }
    XCTAssert(checkedCount == 1, @"Expect 1 checked items");
    
}

- (void)testToPebbleData {
    EDAMNote * note = [[EDAMNote alloc] init];
    note.guid = @"aGuid";
    note.title = @"Hamburger List ƻ";
    note.content = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    @"<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
    @"<en-note><div>ketchup</div><div>mustard</div><div>pickles</div><div><span style=\"text-decoration: line-through;\">beef</span></div><div>w sauce</div><div>buns</div><div>cheese</div><div>mayo</div><div>toms</div><div>lettuce</div><div>onion</div></en-note>";
    ESChecklist *checklist = [[ESChecklist alloc] initWithNote:note];
    
    NSData *pebbleData = [checklist pebbleData];
    UInt8 *bytes = (UInt8 *)pebbleData.bytes;
    int currentOffset = 0;
    int listId = bytes[currentOffset++];
    
    XCTAssertEqual(listId, 0, @"list id should be zero for first list");
    
    char *titleStr =(char*)&(bytes[currentOffset]);
    NSString *title = [NSString stringWithUTF8String:titleStr];
    currentOffset += strlen(titleStr) + 1;
    XCTAssertEqualObjects(note.title, title, "Verify list title in pebble data.");
    
    int count = bytes[currentOffset++];
    
    XCTAssertEqual((int)count, (int)(checklist.items.count), @"Verify item count in pebble data.");
    
    for (int i = 0; i < count; i++) {
        int itemId = bytes[currentOffset++];
        XCTAssertEqual(itemId, i, @"Verify item id");
        
        ESChecklistItem *item = [checklist.items objectAtIndex:i];
        
        char *titleStr =(char*)&(bytes[currentOffset]);
        NSString *title = [NSString stringWithUTF8String:titleStr];
        currentOffset += strlen(titleStr) + 1;
        
        XCTAssertEqualObjects(item.name, title, "Verify item title.");
        
        int flags = bytes[currentOffset++];
        if (item.isChecked) {
            XCTAssertEqual(flags, 1, @"Verify item id");
        } else {
            XCTAssertEqual(flags, 0, @"Verify item id");
        }
    }
    
    XCTAssert(currentOffset == pebbleData.length, @"Make sure we read exactly all of the buffer.");
    
    
}

@end
