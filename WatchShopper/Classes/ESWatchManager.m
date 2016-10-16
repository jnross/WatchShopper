//
//  ESWatchManager.m
//  WatchShopper
//
//  Created by Joseph Ross on 12/7/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <PebbleKit/PebbleKit.h>

#import "ESWatchManager.h"
#import "commands.h"
#import "WatchShopper-Swift.h"

#define PEBBLE_SHOPPER_APP_UUID_STRING @"9ebb1e22-0c72-494e-b5cf-54099e4842e3"

@interface ESWatchManager () <PBPebbleCentralDelegate, EvernoteSynchronizerObserver>

@property(nonatomic,strong) ESChecklist *currentChecklist;
@property(nonatomic,strong) PBWatch *currentWatch;
@property(nonatomic,strong) NSMutableArray *queue;
@property(nonatomic,strong) NSArray<ESChecklist*> *checklists;

@end

@implementation ESWatchManager

static ESWatchManager *singletonInstance = nil;

+ (ESWatchManager *)sharedManager {
    if (singletonInstance == nil) {
        singletonInstance = [[ESWatchManager alloc] init];
    }
    return singletonInstance;
}

- (id)init {
    self = [super init];
    self.queue = [NSMutableArray arrayWithCapacity:5];
    return self;
}

- (void) start {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:PEBBLE_SHOPPER_APP_UUID_STRING];
    uuid_t uuidBytes;
    [uuid getUUIDBytes:uuidBytes];
    NSData *uuidData = [NSData dataWithBytes:uuidBytes length:sizeof(uuidBytes)];
    [[PBPebbleCentral defaultCentral] setAppUUID:uuidData];
    
    [PBPebbleCentral defaultCentral].delegate = self;
    
    [self updateCurrentWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];
    
}

- (void)updateCurrentWatch:(PBWatch*)watch {
    if (watch == self.currentWatch) {
        return;
    }
    
    // Out with the old.
    [self.currentWatch appMessagesRemoveUpdateHandler:self];
    
    // In with the new.
    self.currentWatch = watch;
    [watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        [self receivedUpdate:update fromWatch:watch];
        return YES;
    }];
    [watch appMessagesAddAppLifecycleUpdateHandler:^(PBWatch *watch, NSUUID *uuid, PBAppState newAppState) {
        [self onLifeCyleUpdate:uuid newState:newAppState fromWatch:watch];
    }];
}

- (void)receivedUpdate:(NSDictionary *)update fromWatch:(PBWatch *)watch {
    NSData *data = [update objectForKey:@CMD_LIST_ITEM_UPDATE];
    if (data != nil && data.length >= 3) {
        UInt8 checklistId = ((UInt8*)data.bytes)[0];
        if (checklistId == self.currentChecklist.listId) {
            int currentIndex = 1;
            while (currentIndex < data.length) {
                UInt8 itemId = ((UInt8*)data.bytes)[currentIndex++];
                UInt8 flags = ((UInt8*)data.bytes)[currentIndex++];
                
                ESChecklistItem *item = [self.currentChecklist.items objectAtIndex:itemId];
                item.isChecked = (flags & FLAG_IS_CHECKED) > 0;
                
                [self.currentChecklist.observer checklist:self.currentChecklist updatedItem:item];
            }
        }
    }
    
    data = update[@CMD_GET_STATUS];
    if (data != nil) {
        [self sendChecklistToWatch:self.currentChecklist];
        [self sendAllChecklists];
    }
    
    NSNumber *selectedChecklistNumber = update[@CMD_CHECKLIST_SELECT];
    if (selectedChecklistNumber != nil) {
        [self.observer watchApp:self selectedChecklistAtIndex:selectedChecklistNumber.integerValue];
    }
    
}

- (void)launchWatchAppWithAllChecklists {
    [self.currentWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (error != nil) {
            NSLog(@"appMessagesLaunch error: %@", error);
        }
        [self sendAllChecklists];
    }];
}

- (void)sendAllChecklists {
    for (NSDictionary *dict in self.checklistDataUpdates) {
        [self queueUpdate:dict];
    }
}

- (NSData *)pebbleDataForListName:(NSString *)listName index:(NSUInteger)index {
    const char *utf8name = listName.UTF8String;
    unsigned long nameLength = strlen(utf8name);
    NSMutableData *data = [NSMutableData dataWithCapacity:nameLength + 3];
    UInt8 itemId = index;
    [data appendBytes:&itemId length:1];
    [data appendBytes:utf8name length:nameLength + 1];
    UInt8 flags = 0;
    [data appendBytes:&flags length:1];
    return data;
}

- (NSArray<NSDictionary*>*)checklistDataUpdates {
    NSMutableData *data = [NSMutableData data];
    NSMutableArray *updates = [NSMutableArray arrayWithObject:@{@CMD_CHECKLISTS_START:data}];
    
    // First byte is the 1-byte list ID
    UInt8 listId = 0;
    [data appendBytes:&listId length:1];
    
    //Append the null-terminated list name
    const char *utf8name = @"Lists".UTF8String;
    [data appendBytes:utf8name length:strlen(utf8name) + 1];
    
    //Append 1-byte list item count
    UInt8 count = self.checklists.count;
    [data appendBytes:&count length:1];
    
    //Concatenate list items
    int i = 0;
    for (ESChecklist *aList in self.checklists) {
        NSData *itemData = [self pebbleDataForListName:aList.name index:i];
        if (data.length + itemData.length > 110) {
            data = [NSMutableData data];
            [updates addObject:@{@CMD_CHECKLISTS_CONTINUATION:data}];
        }
        [data appendData:itemData];
        i++;
    }
    
    return updates;
}

- (void)sendChecklistToWatch:(ESChecklist *)checklist {
    self.currentChecklist = checklist;
    NSArray *updates = checklist.pebbleDataUpdates;
    for (NSDictionary *update in updates) {
        [self queueUpdate:update];
    }
    
}

- (void)launchWatchApp {
    [self.currentWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (error != nil) {
            NSLog(@"appMessagesLaunch error: %@", error);
        }
    }];
}

- (void)getListStatus {
    uint8_t cmd = CMD_GET_LIST_STATUS;
    NSData *data = [NSData dataWithBytes:&cmd length:1];
    NSDictionary *update = @{@CMD_GET_LIST_STATUS: data};
    [self queueUpdate:update];
}

- (void)queueUpdate:(NSDictionary *)update {
    BOOL triggerSend = (self.queue.count == 0);
    [self.queue addObject:update];
    if (triggerSend) {
        [self doSend];
    }
}

- (void)doSend {
    if (self.queue.count > 0) {
        NSDictionary *update = self.queue[0];
        [self.currentWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
            if (error != nil) {
                NSLog(@"appMessagesPushUpdate error: %@", error);
            }
            [self.queue removeObjectAtIndex:0];
            [self doSend];
        }];
    }
}

- (void)synchronizer:(EvernoteSynchronizer*)synchronizer updatedChecklists:(NSArray<ESChecklist*>*)checklists {
    self.checklists = checklists;
}

- (void)sendChecklistItemUpdate:(ESChecklistItem *)item {
    if ([self.currentChecklist.items containsObject:item]) {
        UInt8 buf[3];
        buf[0] = 0x00;
        buf[1] = item.itemId;
        buf[2] = item.isChecked ? FLAG_IS_CHECKED : 0x00;
        NSData *data = [NSData dataWithBytes:buf length:3];
        NSDictionary *update = @{@CMD_LIST_ITEM_UPDATE: data};
        [self.currentWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
            if (error != nil) {
                NSLog(@"appMessagesPushUpdate error: %@", error);
            }
        }];
    }
    
}

- (void)onLifeCyleUpdate:(NSUUID*)uuid newState:(PBAppState)newState fromWatch:(PBWatch *)watch {
    
    
}

#pragma mark - PBPebbleCentralDelegate implementation

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    [self updateCurrentWatch:watch];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {}


@end
