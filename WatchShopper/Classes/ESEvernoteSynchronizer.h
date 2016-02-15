//
//  ESEvernoteSynchronizer.h
//  WatchShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ENSDKAdvanced.h"

#define EVERNOTE [ESEvernoteSynchronizer sharedSynchronizer]

@class ESEvernoteSynchronizer;
@class ESChecklist;
@protocol ESEvernoteSynchronizerObserver <NSObject>

- (void)synchronizerUpdatedChecklists:(ESEvernoteSynchronizer *) synchronizer;

@end

@interface ESEvernoteSynchronizer : NSObject

+ (void)setupEvernoteSingleton;
+ (ESEvernoteSynchronizer *)sharedSynchronizer;

- (void)addObserver:(NSObject<ESEvernoteSynchronizerObserver> *)observer;
- (void)removeObserver:(NSObject<ESEvernoteSynchronizerObserver> *)observer;
- (void)authenticateEvernoteUserFromViewController:(UIViewController*)viewController;
- (BOOL)isAlreadyAutheticated;
- (void)getPebbleNotes;
- (NSArray<ESChecklist *>*)checklists;
- (void)saveNote:(EDAMNote *)note;
- (NSArray *)checklistDataUpdates;
- (void)logout;
- (void)loadContentForChecklist:(ESChecklist *)checklist success:(void (^)())success failure:(void (^)(NSError* error))failure;

@property (nonatomic,retain) NSArray *allNotebookNames;
@property (nonatomic) BOOL isGathering;

@end
