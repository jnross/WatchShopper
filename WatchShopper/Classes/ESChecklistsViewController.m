//
//  ESViewController.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklistsViewController.h"
#import "ESEvernoteSynchronizer.h"
#import "ESWatchManager.h"
#import "ESChecklistItemsViewController.h"

@interface ESChecklistsViewController () <ESEvernoteSynchronizerObserver, ESWatchManagerObserver>

@property(nonatomic,strong) IBOutlet UILabel *authStatusLabel;

@end

@implementation ESChecklistsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    self.refreshControl = refreshControl;
    [refreshControl addTarget:self action:@selector(pulledToRefresh:) forControlEvents:UIControlEventValueChanged];
    
    [EVERNOTE addObserver:self];
    if ([EVERNOTE isAlreadyAutheticated]) {
        self.authStatusLabel.text = @"Already authenticated!";
        
    }
    
    [self refreshNotes];
    
    [[ESWatchManager sharedManager] start];
    [ESWatchManager sharedManager].observer = self;
}

- (void)dealloc {
    [EVERNOTE removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void) refreshNotes {
    if ([EVERNOTE isAlreadyAutheticated]) {
        [EVERNOTE getPebbleNotes];
    } else {
        [EVERNOTE authenticateEvernoteUserFromViewController:self];
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


- (void)synchronizerUpdatedChecklists:(ESEvernoteSynchronizer *) synchronizer {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [[ESWatchManager sharedManager] launchWatchAppWithAllChecklists];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return EVERNOTE.checklists.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Checklist"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Checklist"];
    }
    
    ESChecklist *checklist = [EVERNOTE.checklists objectAtIndex:indexPath.row];
    
    cell.textLabel.text = checklist.name;
    
    cell.detailTextLabel.text = [ESChecklist niceLookingStringForDate:checklist.lastUpdatedDate];
    
    return cell;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ESChecklist *checklist = sender;
    if ([segue.destinationViewController isKindOfClass:ESChecklistItemsViewController.class]) {
        ESChecklistItemsViewController *itemsView = segue.destinationViewController;
        itemsView.checklist = checklist;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESChecklist *checklist = EVERNOTE.checklists[indexPath.row];
    
    [self loadAndPushChecklist:checklist];
}

- (void)loadAndPushChecklist:(ESChecklist *)checklist {
    if (checklist.note.content != nil) {
        [self pushChecklist:checklist];
    } else {
        [EVERNOTE loadContentForChecklist:checklist success:^{
            [self pushChecklist:checklist];
        } failure:^(NSError *error) {
            //Alert the failure
        }];
    }
}

- (void)pushChecklist:(ESChecklist *)checklist {
    
    [self performSegueWithIdentifier:@"push" sender:checklist];
    
    [[ESWatchManager sharedManager] launchWatchApp];
    [[ESWatchManager sharedManager] sendChecklistToWatch:checklist];
}

- (void) watchApp:(ESWatchManager*)watchApp selectedChecklistAtIndex:(NSInteger)selectedChecklistIndex {
    NSArray *checklists = [EVERNOTE checklists];
    if (checklists.count > selectedChecklistIndex) {
        ESChecklist *selectedChecklist = checklists[selectedChecklistIndex];
        if (self.navigationController.topViewController != self) {
            [self.navigationController popToViewController:self animated:NO];
        }
        [self loadAndPushChecklist:selectedChecklist];
    }
}

@end
