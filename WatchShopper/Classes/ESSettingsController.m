//
//  ESSettingsController.m
//  WatchShopper
//
//  Created by Joseph Norman Ross on 1/11/14.
//  Copyright (c) 2014 Easy Street 3. All rights reserved.
//

#import "ESSettingsController.h"
#import "ESSettingsManager.h"
#import "ESAddTagCell.h"
#import "version.h"
#import "WatchShopper-Swift.h"

#define SECTION_AUTHORIZE_EVERNOTE 0
#define SECTION_INSTALL_WATCHAPP 1
#define SECTION_TAGS 2
#define SECTION_NOTEBOOKS 3
#define SECTION_VERSION 4
#define NUM_SECTIONS 5

@interface ESSettingsController () <UITextFieldDelegate, UIAlertViewDelegate>

@property(nonatomic,strong) NSArray *targetTags;
@property(nonatomic,strong) NSArray *targetNotebookNames;

- (IBAction)tagTextEntered:(UITextField*)tagTextField;

@end

@implementation ESSettingsController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)donePressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)tagTextEntered:(UITextField*)tagTextField {
    [[ESSettingsManager sharedManager] addTargetTag:tagTextField.text];
    NSInteger insertRowIndex = self.targetTags.count;
    self.targetTags = [[ESSettingsManager sharedManager] targetTags];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:insertRowIndex inSection:SECTION_TAGS]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:insertRowIndex inSection:SECTION_TAGS]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.targetTags = [[ESSettingsManager sharedManager] targetTags];
    self.allNotebookNames = [[EvernoteSynchronizer shared] allNotebookNames];
    self.targetNotebookNames = [[ESSettingsManager sharedManager] targetNotebookNames];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (NSInteger)numberOfLabelRows {
    return self.targetTags.count + 1;
}

- (NSInteger)numberOfNotebookRows {
    return self.allNotebookNames.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_AUTHORIZE_EVERNOTE:
            return @"Evernote";
            break;
        case SECTION_INSTALL_WATCHAPP:
            return @"Install";
            break;
        case SECTION_TAGS:
            return @"Tags to Sync";
            break;
        case SECTION_NOTEBOOKS:
            return @"Notebooks to Sync";
            break;
        case SECTION_VERSION:
            return @"Version";
            break;
        default:
            break;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SECTION_AUTHORIZE_EVERNOTE:
            return 1;
            break;
        case SECTION_INSTALL_WATCHAPP:
            return 1;
            break;
        case SECTION_TAGS:
            return [self numberOfLabelRows];
            break;
        case SECTION_NOTEBOOKS:
            return [self numberOfNotebookRows];
            break;
        case SECTION_VERSION:
            return 1;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case SECTION_AUTHORIZE_EVERNOTE:
            cell = [self evernoteAuthorizationCell];
            break;
        case SECTION_INSTALL_WATCHAPP:
            cell = [self installWatchappCell];
            break;
        case SECTION_TAGS:
            cell = [self tagCellForRow:indexPath.row];
            break;
        case SECTION_NOTEBOOKS:
            cell = [self notebookCellForRow:indexPath.row];
            break;
        case SECTION_VERSION:
            cell = [self versionCell];
            break;
        default:
            break;
    }
    
    return cell;
}

- (UITableViewCell *)versionCell {
    static NSString *CellIdentifier = @"VersionCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = BUILD_VERSION;
    
    return cell;
}

- (UITableViewCell *)installWatchappCell {
    static NSString *CellIdentifier = @"InstallWatchappCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = @"Install WatchShopper Watchapp";
    
    return cell;
}

- (UITableViewCell *)evernoteAuthorizationCell {
    static NSString *CellIdentifier = @"EvernoteAuthorizationCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if ([[EvernoteSynchronizer shared] isAlreadyAuthenticated]) {
        cell.textLabel.text = @"Log Out and Re-Authorize";
    } else {
        cell.textLabel.text = @"Authorize Evernote";
    }
    
    return cell;
}

- (UITableViewCell *)addTagCell {
    static NSString *CellIdentifier = @"AddTagCell";
    ESAddTagCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textField.text = nil;
    return cell;
}

- (UITableViewCell *)tagCellForRow:(NSInteger)row {
    
    if (row >= self.targetTags.count) {
        return [self addTagCell];
    }
    
    static NSString *CellIdentifier = @"TagCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    }
    NSString *labelText = self.targetTags[row];
    
    cell.textLabel.text = labelText;
    return cell;
}

- (UITableViewCell *)notebookCellForRow:(NSInteger)row {
    
    static NSString *CellIdentifier = @"NotebookCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *labelText = self.allNotebookNames[row];
    if ([self.targetNotebookNames containsObject:labelText]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = labelText;
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSString *tag = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        [[ESSettingsManager sharedManager] removeTargetTag:tag];
        self.targetTags = [[ESSettingsManager sharedManager] targetTags];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case SECTION_AUTHORIZE_EVERNOTE:
            if ([[EvernoteSynchronizer shared] isAlreadyAuthenticated]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm Logout" message:@"Log out current Evernote account?" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    [self userConfirmedLogout];
                }]];
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            } else {
                [[EvernoteSynchronizer shared] authenticateEvernoteUserWithViewController:self];
            }
            break;
        case SECTION_INSTALL_WATCHAPP: {
            NSString *url = @"pebble://appstore/52bf023e007c1ebd8500008c";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:^(BOOL success) {}];
        }
            break;
        case SECTION_TAGS:
            break;
        case SECTION_NOTEBOOKS:
        {
            NSString *notebookName = self.allNotebookNames[indexPath.row];
            [[ESSettingsManager sharedManager] toggleNotebook:notebookName];
            self.targetNotebookNames = [[ESSettingsManager sharedManager] targetNotebookNames];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            
            break;
            
        default:
            break;
    }
}


- (void)userConfirmedLogout {
    [[EvernoteSynchronizer shared] logout];
    [[EvernoteSynchronizer shared] authenticateEvernoteUserWithViewController:self];
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
