//
//  ESChecklistItemsViewController.h
//  PebbleShopper
//
//  Created by Joseph Ross on 12/10/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESChecklist.h"

@interface ESChecklistItemsViewController : UITableViewController

@property(nonatomic,strong) ESChecklist *checklist;

- (id)initWithChecklist:(ESChecklist *)checklist;

@end
