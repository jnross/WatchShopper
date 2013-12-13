//
//  ESWatchManager.h
//  PebbleShopper
//
//  Created by Joseph Ross on 12/7/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ESChecklist.h"

#define APP_MESSAGE_SIZE_MAX 124

@interface ESWatchManager : NSObject

+ (ESWatchManager *)sharedManager;

- (void)start;
- (void)sendChecklistToWatch:(ESChecklist *)checklist;
- (void)sendChecklistItemUpdate:(ESChecklistItem *)item;
- (void)launchWatchAppWithChecklist:(ESChecklist *)checklist;

@end
