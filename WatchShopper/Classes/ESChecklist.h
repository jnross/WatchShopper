//
//  ESChecklist.h
//  PebbleShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EvernoteSDK.h"
#import "ESChecklistItem.h"

@class ESChecklist;

@protocol ESChecklistObserver <NSObject>

- (void)checklistDidRefresh:(ESChecklist *)checklist;
- (void)checklist:(ESChecklist *)checklist updatedItem:(ESChecklistItem *) item;

@end

@interface ESChecklist : NSObject

@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSString *guid;
@property(nonatomic,strong) EDAMNote *note;
@property(nonatomic,strong) NSDate *lastUpdatedDate;
@property(nonatomic,strong) NSMutableArray *items;
@property(nonatomic,weak) NSObject<ESChecklistObserver> *observer;

- (id)initWithName:(NSString *)name guid:(NSString *)guid;
- (id)initWithNote:(EDAMNote *)note;
- (void)saveToEvernote;
- (NSArray *)pebbleDataUpdates;
- (void)loadContent;

@end
