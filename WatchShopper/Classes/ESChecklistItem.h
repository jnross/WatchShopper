//
//  ESChecklistItem.h
//  WatchShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESChecklistItem : NSObject

@property(nonatomic,strong) NSString *name;
@property(nonatomic) UInt8 itemId;
@property(nonatomic) BOOL isChecked;

- (id)initWithName:(NSString *)name itemId:(UInt8)itemId;

- (NSData *)pebbleData;

@end
