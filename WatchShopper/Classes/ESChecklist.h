//
//  ESChecklist.h
//  WatchShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ENSDKAdvanced.h"
#import "ESChecklistItem.h"

@class ESChecklist;

@protocol ESChecklistObserver <NSObject>

- (void)checklistDidRefresh:(nonnull ESChecklist *)checklist;
- (void)checklist:(nonnull ESChecklist *)checklist updatedItem:(nonnull ESChecklistItem *) item;

@end

@interface ESChecklist : NSObject

@property(nonatomic,strong,nonnull) NSString *name;
@property(nonatomic,strong,nonnull) NSString *guid;
@property(nonatomic) NSInteger listId;
@property(nonatomic,strong,nullable) EDAMNote *note;
@property(nonatomic,strong,nonnull) NSDate *lastUpdatedDate;
@property(nonatomic,weak,nullable) NSObject<ESChecklistObserver> *observer;

- (nonnull instancetype)initWithName:(nonnull NSString *)name guid:(nonnull NSString *)guid;
- (nonnull instancetype)initWithNote:(nonnull EDAMNote *)note;
- (void)saveToEvernote;
- (nonnull NSArray *)pebbleDataUpdates;
- (void)loadContent;
- (nonnull NSArray<ESChecklistItem *> *)items;

+ (nullable NSString*)niceLookingStringForDate:(nonnull NSDate*)date;

@end
