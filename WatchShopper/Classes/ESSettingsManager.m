//
//  ESSettingsManager.m
//  WatchShopper
//
//  Created by Joseph Norman Ross on 1/12/14.
//  Copyright (c) 2014 Easy Street 3. All rights reserved.
//

#import "ESSettingsManager.h"

#define KEY_TARGET_TAGS @"targetTags"
#define KEY_TARGET_NOTEBOOKS @"targetNotebooks"

@interface ESSettingsManager ()

@end

@implementation ESSettingsManager

static ESSettingsManager *singletonInstance = nil;
+ (ESSettingsManager *) sharedManager {
    if (singletonInstance == nil) {
        singletonInstance = [[ESSettingsManager alloc] init];
    }
    return singletonInstance;
}

- (void)setUpInitialSettingsIfNecessary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *targetTags = [defaults objectForKey:KEY_TARGET_TAGS];
    if (targetTags == nil) {
        [defaults setObject:@[@"WatchShopper", @"pebble"] forKey:KEY_TARGET_TAGS];
        [defaults setObject:@[] forKey:KEY_TARGET_NOTEBOOKS];
        [defaults synchronize];
    }
    
}

- (NSArray*) targetTags {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:KEY_TARGET_TAGS];
}

- (NSArray*) targetNotebookNames {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:KEY_TARGET_NOTEBOOKS];
}

- (void) addTargetTag:(NSString *)label {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *targetTags = [defaults objectForKey:KEY_TARGET_TAGS];
    if (![targetTags containsObject:label]) {
        targetTags = [targetTags arrayByAddingObject:label];
        [defaults setObject:targetTags forKey:KEY_TARGET_TAGS];
        [defaults synchronize];
    }
}

- (void) removeTargetTag:(NSString*)tag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *targetTags = [defaults objectForKey:KEY_TARGET_TAGS];
    if ([targetTags containsObject:tag]) {
        NSMutableArray *mutableTargetTags = [targetTags mutableCopy];
        [mutableTargetTags removeObject:tag];
        [defaults setObject:mutableTargetTags forKey:KEY_TARGET_TAGS];
        [defaults synchronize];
    }
}


- (void) toggleNotebook:(NSString *)notebookName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *targetNotebooks = [[defaults objectForKey:KEY_TARGET_NOTEBOOKS] mutableCopy];
    if (targetNotebooks == nil) {
        targetNotebooks = [NSMutableArray array];
    }
    if ([targetNotebooks containsObject:notebookName]) {
        [targetNotebooks removeObject: notebookName];
    } else {
        [targetNotebooks addObject: notebookName];
    }
    [defaults setObject:targetNotebooks forKey:KEY_TARGET_NOTEBOOKS];
}

@end
