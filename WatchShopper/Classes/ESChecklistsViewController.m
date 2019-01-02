//
//  ESViewController.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklistsViewController.h"
#import "WatchShopper-Swift.h"
#import "EvernoteSDK/EvernoteSDK.h"

@interface ESChecklistsViewController () <EvernoteSynchronizerObserver>

@property(nonatomic,strong) IBOutlet UILabel *authStatusLabel;
@property(nonatomic,strong) NSArray<Checklist*>* checklists;

@end

@implementation ESChecklistsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    self.refreshControl = refreshControl;
    [refreshControl addTarget:self action:@selector(pulledToRefresh:) forControlEvents:UIControlEventValueChanged];
    
    [EvernoteSynchronizer.shared addObserver:self];
    if ([EvernoteSynchronizer.shared isAlreadyAuthenticated]) {
        self.authStatusLabel.text = @"Already authenticated!";
        
    }
    
    [self refreshNotes];
}

- (void)dealloc {
    [EvernoteSynchronizer.shared removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void) refreshNotes {
    if ([EvernoteSynchronizer.shared isAlreadyAuthenticated]) {
        [EvernoteSynchronizer.shared refreshWatchNotes];
    } else {
        [EvernoteSynchronizer.shared authenticateEvernoteUserWithViewController:self];
    }
}

- (IBAction)pulledToRefresh:(id)sender {
    [self refreshNotes];
}

- (IBAction)settingsButtonPressed:(id)sender {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)synchronizer:(EvernoteSynchronizer *) synchronizer updatedChecklists:(NSArray<Checklist*>*)checklists {
    self.checklists = checklists;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.checklists.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Checklist"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Checklist"];
    }
    
    Checklist *checklist = [self.checklists objectAtIndex:indexPath.row];
    
    cell.textLabel.text = checklist.name;
    
    cell.detailTextLabel.text = checklist.prettyDateString;
    
    return cell;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Checklist *checklist = sender;
    if ([segue.destinationViewController isKindOfClass:ChecklistItemsViewController.class]) {
        ChecklistItemsViewController *itemsView = segue.destinationViewController;
        itemsView.checklist = checklist;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Checklist *checklist = self.checklists[indexPath.row];
    
    [self loadAndPushChecklist:checklist];
}

- (void)loadAndPushChecklist:(Checklist *)checklist {
    if (checklist.note.content != nil) {
        [self pushChecklist:checklist];
    } else {
        [EvernoteSynchronizer.shared loadContentFor:checklist success:^{
            [self pushChecklist:checklist];
        } failure:^(NSError *error) {
            //Alert the failure
        }];
    }
}

- (void)pushChecklist:(Checklist *)checklist {
    
    [self performSegueWithIdentifier:@"push" sender:checklist];
}

@end
