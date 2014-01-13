//
//  ESSettingsController.m
//  WatchShopper
//
//  Created by Joseph Norman Ross on 1/11/14.
//  Copyright (c) 2014 Easy Street 3. All rights reserved.
//

#import "ESSettingsController.h"

#define SECTION_AUTHORIZE_EVERNOTE 0
#define SECTION_LABELS 1
#define SECTION_NOTEBOOKS 2
#define NUM_SECTIONS 3

@interface ESSettingsController ()

@property(nonatomic,strong) NSMutableArray *targetLabels;
@property(nonatomic,strong) NSMutableArray *targetNotebookNames;

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return self.targetLabels.count + 1;
}

- (NSInteger)numberOfNotebookRows {
    return self.allNotebookNames.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SECTION_AUTHORIZE_EVERNOTE:
            return 1;
            break;
        case SECTION_LABELS:
            return [self numberOfLabelRows];
            break;
        case SECTION_NOTEBOOKS:
            return [self numberOfNotebookRows];
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
        case SECTION_LABELS:
            cell = [self labelCellForRow:indexPath.row];
            break;
        case SECTION_NOTEBOOKS:
            cell = [self notebookCellForRow:indexPath.row];
            break;
        default:
            break;
    }
    
    return cell;
}

- (UITableViewCell *)evernoteAuthorizationCell {
    static NSString *CellIdentifier = @"EvernoteAuthorizationCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = @"Authorize Evernote";
    return cell;
}

- (UITableViewCell *)addLabelCell {
    static NSString *CellIdentifier = @"AddLabelCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.text = @"Add Label to Sync";
        cell.textLabel.textColor = [UIColor grayColor];
    }
    
    return cell;
}

- (UITableViewCell *)labelCellForRow:(NSInteger)row {
    
    if (row >= self.targetLabels.count) {
        return [self addLabelCell];
    }
    
    static NSString *CellIdentifier = @"LabelCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *labelText = self.targetLabels[row];
    
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
    
    cell.textLabel.text = labelText;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
