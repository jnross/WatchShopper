//
//  ESWatchManager.m
//  PebbleShopper
//
//  Created by Joseph Ross on 12/7/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <PebbleKit/PebbleKit.h>

#import "ESWatchManager.h"
#import "ESEvernoteSynchronizer.h"

#define PEBBLE_SHOPPER_APP_UUID_STRING @"9ebb1e22-0c72-494e-b5cf-54099e4842e3"

#define FLAG_IS_CHECKED 0x01

@interface ESWatchManager () <PBPebbleCentralDelegate>

@property(nonatomic,strong) ESChecklist *currentChecklist;
@property(nonatomic,strong) PBWatch *currentWatch;
@property(nonatomic,strong) NSMutableArray *queue;

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
    NSData *data = [update objectForKey:@1];
    if (data != nil && data.length >= 3) {
        //UInt8 checklistId = ((UInt8*)data.bytes)[0];
        UInt8 itemId = ((UInt8*)data.bytes)[1];
        UInt8 flags = ((UInt8*)data.bytes)[2];
        
        ESChecklistItem *item = [self.currentChecklist.items objectAtIndex:itemId];
        item.isChecked = (flags & FLAG_IS_CHECKED) > 0;
        
        [self.currentChecklist.observer checklist:self.currentChecklist updatedItem:item];
    }
    
    data = update[@3];
    if (data != nil) {
        [self sendChecklistToWatch:self.currentChecklist];
        [self sendAllChecklists];
    }
    
    NSNumber *selectedChecklistNumber = update[@5];
    if (selectedChecklistNumber != nil) {
        [self.observer watchApp:self selectedChecklistAtIndex:selectedChecklistNumber.integerValue];
    }
    
}

- (void)sendAllChecklists {
    for (NSDictionary *dict in EVERNOTE.checklistDataUpdates) {
        [self queueUpdate:dict];
    }
}

- (void)sendChecklistToWatch:(ESChecklist *)checklist {
    self.currentChecklist = checklist;
    NSArray *updates = checklist.pebbleDataUpdates;
    for (NSDictionary *update in updates) {
        [self queueUpdate:update];
    }
    
}

- (void)launchWatchAppWithChecklist:(ESChecklist *)checklist {
    self.currentChecklist = checklist;
    [self.currentWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (error != nil) {
            NSLog(@"appMessagesLaunch error: %@", error);
        }
        [self sendChecklistToWatch:self.currentChecklist];
    }];
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

- (void)sendChecklistItemUpdate:(ESChecklistItem *)item {
    if ([self.currentChecklist.items containsObject:item]) {
        UInt8 buf[3];
        buf[0] = 0x00;
        buf[1] = item.itemId;
        buf[2] = item.isChecked ? 0x01 : 0x00;
        NSData *data = [NSData dataWithBytes:buf length:3];
        NSDictionary *update = @{@1: data};
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
