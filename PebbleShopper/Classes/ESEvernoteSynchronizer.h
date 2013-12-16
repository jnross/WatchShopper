//
//  ESEvernoteSynchronizer.h
//  PebbleShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EvernoteSDK.h"

#define EVERNOTE [ESEvernoteSynchronizer sharedSynchronizer]

@class ESEvernoteSynchronizer;
@protocol ESEvernoteSynchronizerDelegate <NSObject>

- (void)synchronizerUpdatedChecklists:(ESEvernoteSynchronizer *) synchronizer;

@end

@interface ESEvernoteSynchronizer : NSObject

@property(nonatomic, weak) NSObject<ESEvernoteSynchronizerDelegate> *delegate;

+ (void)setupEvernoteSingleton;
+ (ESEvernoteSynchronizer *)sharedSynchronizer;

- (void)authenticateEvernoteUserFromViewController:(UIViewController*)viewController;
- (BOOL)isAlreadyAutheticated;
- (void)getPebbleNotes;
- (NSArray*)checklists;
- (void)saveNote:(EDAMNote *)note;

@end
