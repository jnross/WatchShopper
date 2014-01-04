//
//  ESChecklistItem.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklistItem.h"

@implementation ESChecklistItem

- (id)initWithName:(NSString *)name itemId:(UInt8)itemId {
    self = [super init];
    self.name = name;
    self.itemId = itemId;
    return self;
}

- (NSData *)pebbleData {
    const char *utf8name = self.name.UTF8String;
    unsigned long nameLength = strlen(utf8name);
    NSMutableData *data = [NSMutableData dataWithCapacity:nameLength + 3];
    UInt8 itemId = self.itemId;
    [data appendBytes:&itemId length:1];
    [data appendBytes:utf8name length:nameLength + 1];
    UInt8 flags = 0;
    if (self.isChecked) {
        flags |= 0x01;
    }
    [data appendBytes:&flags length:1];
    return data;
}

@end
