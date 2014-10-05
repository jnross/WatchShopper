//
//  ESChecklistItemsViewController.m
//  WatchShopper
//
//  Created by Joseph Ross on 12/10/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklistItemsViewController.h"
#import "ESWatchManager.h"

@interface ESChecklistItemsViewController () <ESChecklistObserver>

@end

@implementation ESChecklistItemsViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = self.checklist.name;
    self.checklist.observer = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ESChecklistObserver
- (void)checklistDidRefresh:(ESChecklist *)checklist {}
- (void)checklist:(ESChecklist *)checklist updatedItem:(ESChecklistItem *) item {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:item.itemId inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.checklist.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Item";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ESChecklistItem *item = self.checklist.items[indexPath.row];
    cell.textLabel.text = item.name;
    
    if (item.isChecked) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ESChecklistItem *item = self.checklist.items[indexPath.row];
    item.isChecked = !(item.isChecked);
    [[ESWatchManager sharedManager] sendChecklistItemUpdate:item];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isViewLoaded && self.view.window) {
        [[ESWatchManager sharedManager] getListStatus];
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[ESWatchManager sharedManager] launchWatchApp];
        });
    }
}

- (IBAction)savePressed:(id)sender {
    [self.checklist saveToEvernote];
}

@end
