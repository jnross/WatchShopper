//
//  ESSettingsManager.h
//  WatchShopper
//
//  Created by Joseph Norman Ross on 1/12/14.
//  Copyright (c) 2014 Easy Street 3. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESSettingsManager : NSObject
+ (ESSettingsManager *) sharedManager;

- (void)setUpInitialSettingsIfNecessary;
- (NSArray<NSString*>*) targetTags;
- (NSArray<NSString*>*) targetNotebookNames;
- (void) addTargetTag:(NSString *)label;
- (void) removeTargetTag:(NSString *)label;
- (void) toggleNotebook:(NSString *)notebookName;
@end
