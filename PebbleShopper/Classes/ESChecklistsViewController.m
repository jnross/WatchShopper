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

@interface ESChecklistsViewController () <ESEvernoteSynchronizerDelegate>

@property(nonatomic,strong) IBOutlet UILabel *authStatusLabel;

@end

@implementation ESChecklistsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    EVERNOTE.delegate = self;
    if ([EVERNOTE isAlreadyAutheticated]) {
        self.authStatusLabel.text = @"Already authenticated!";
        
    }
    
    if ([EVERNOTE isAlreadyAutheticated]) {
        [EVERNOTE getPebbleNotes];
    } else {
        [EVERNOTE authenticateEvernoteUserFromViewController:self];
    }
    
    [[ESWatchManager sharedManager] start];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(settingsButtonPressed:)];
    
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
