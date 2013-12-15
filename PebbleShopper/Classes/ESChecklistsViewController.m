//
//  ESViewController.m
//  PebbleShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklistsViewController.h"
#import "ESEvernoteSynchronizer.h"
#import "ESWatchManager.h"
#import "ESChecklistItemsViewController.h"
#import "TTTTimeIntervalFormatter.h"

@interface ESChecklistsViewController () <ESEvernoteSynchronizerDelegate>

@property(nonatomic,strong) IBOutlet UILabel *authStatusLabel;
@property(nonatomic,strong) TTTTimeIntervalFormatter *formatter;

@end

@implementation ESChecklistsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    self.refreshControl = refreshControl;
    [refreshControl addTarget:self action:@selector(pulledToRefresh:) forControlEvents:UIControlEventValueChanged];
    
    EVERNOTE.delegate = self;
    if ([EVERNOTE isAlreadyAutheticated]) {
        self.authStatusLabel.text = @"Already authenticated!";
        
    }
    
    [self refreshNotes];
    
    [[ESWatchManager sharedManager] start];
    
    self.formatter = [[TTTTimeIntervalFormatter alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(settingsButtonPressed:)];
    
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
    
    NSTimeInterval interval = [checklist.lastUpdatedDate timeIntervalSinceNow];
    
    NSTimeInterval twoDaysAgo = -60 * 60 * 24 * 2;
    NSString *dateString = nil;
    if (interval < twoDaysAgo) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, MMM dd, yyyy"];
        dateString = [dateFormatter stringFromDate:checklist.lastUpdatedDate];
    } else {
        dateString = [self.formatter stringForTimeInterval:interval];
    }
    cell.detailTextLabel.text = dateString;
    
    return cell;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ESChecklist *checklist = sender;
    ESChecklistItemsViewController *itemsView = segue.destinationViewController;
    itemsView.checklist = checklist;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESChecklist *checklist = EVERNOTE.checklists[indexPath.row];
    
//    ESChecklistItemsViewController *itemView = [[ESChecklistItemsViewController alloc] initWithChecklist:checklist];
//    [self.navigationController pushViewController:itemView animated:YES];
    [self performSegueWithIdentifier:@"push" sender:checklist];
    
    [[ESWatchManager sharedManager] launchWatchAppWithChecklist:checklist];
}

@end
