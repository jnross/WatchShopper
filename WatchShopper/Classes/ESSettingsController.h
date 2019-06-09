//
//  ESSettingsController.h
//  WatchShopper
//
//  Created by Joseph Norman Ross on 1/11/14.
//  Copyright (c) 2014 Easy Street 3. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ESSettingsController;

@protocol ESSettingsControllerDelegate <NSObject>

- (void)settingsController:(ESSettingsController*) settings willDismissNeedingReload: (Boolean) needsReload;

@end

@interface ESSettingsController : UITableViewController

@property(nonatomic,strong) NSArray *allNotebookNames;
@property(nonatomic,weak)   IBOutlet NSObject<ESSettingsControllerDelegate>* settingsDelegate;

@end
