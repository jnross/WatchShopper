//
//  WatchShopperTests.m
//  WatchShopperTests
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface WatchShopperTests : XCTestCase

@end

@implementation WatchShopperTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"Hello" forKey:@"hello"];
    [defaults synchronize];
    
    defaults = [NSUserDefaults standardUserDefaults];
    id result = [defaults objectForKey:@"hello"];
    XCTAssertNotNil(result);
}

@end
