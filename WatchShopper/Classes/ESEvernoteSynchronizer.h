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

- (void)synchronizerUpdatedChecklists:(nonnull ESEvernoteSynchronizer *) synchronizer;

@end

@interface ESEvernoteSynchronizer : NSObject

+ (void)setupEvernoteSingleton;
+ (nonnull ESEvernoteSynchronizer *)sharedSynchronizer;

- (void)addObserver:(nonnull NSObject<ESEvernoteSynchronizerObserver> *)observer;
- (void)removeObserver:(nonnull NSObject<ESEvernoteSynchronizerObserver> *)observer;
- (void)authenticateEvernoteUserFromViewController:(nonnull UIViewController*)viewController;
- (BOOL)isAlreadyAutheticated;
- (void)getPebbleNotes;
- (nonnull NSArray<ESChecklist *>*)checklists;
- (void)saveNote:(nonnull EDAMNote *)note;
- (nonnull NSArray *)checklistDataUpdates;
- (void)logout;
- (void)loadContentForChecklist:(nonnull ESChecklist *)checklist success:(nullable void (^)())success failure:(nullable void (^)( NSError* _Nonnull error))failure;

@property (nonatomic,retain,nonnull) NSArray *allNotebookNames;
@property (nonatomic) BOOL isGathering;

@end
