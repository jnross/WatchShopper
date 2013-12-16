//
//  ESEvernoteSynchronizer.m
//  PebbleShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESEvernoteSynchronizer.h"
#import "EvernoteSDK.h"
#import "ESChecklist.h"

static ESEvernoteSynchronizer *singletonInstance = nil;

@interface ESEvernoteSynchronizer ()

@property(nonatomic,strong) NSMutableArray* mutableChecklists;

@end

@implementation ESEvernoteSynchronizer

+ (void)setupEvernoteSingleton {
    NSString *EVERNOTE_HOST = BootstrapServerBaseURLStringSandbox;
    NSString *CONSUMER_KEY = @"jnross";
    NSString *CONSUMER_SECRET = @"bc29b5c96d1461d6";
    
    // set up Evernote session singleton
    [EvernoteSession setSharedSessionHost:EVERNOTE_HOST
                              consumerKey:CONSUMER_KEY
                           consumerSecret:CONSUMER_SECRET];
}

+ (ESEvernoteSynchronizer *)sharedSynchronizer {
    if (singletonInstance == nil) {
        singletonInstance = [[ESEvernoteSynchronizer alloc] init];
    }
    return singletonInstance;
}

- (id)init {
    
    self = [super init];
    self.mutableChecklists = [NSMutableArray array];
    
    
    return self;
}

- (void)authenticateEvernoteUserFromViewController:(UIViewController*)viewController {
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithViewController:viewController completionHandler:^(NSError *error) {
        if (error || !session.isAuthenticated) {
            // authentication failed :(
            // show an alert, etc
            // ...
        } else {
            [self getPebbleNotes];
        } 
    }];
}

- (BOOL)isAlreadyAutheticated {
    return [[EvernoteSession sharedSession] authenticationToken] != nil;
}

- (void)saveNote:(EDAMNote *)note {
    [[EvernoteNoteStore noteStore] updateNote:note
                                      success:^(EDAMNote *note) {
                                          
                                      }
                                      failure:^(NSError *error) {
                                          NSLog(@"Failed to update note: %@", error);
                                      }];
}

- (void)getPebbleNotes {
    [self.mutableChecklists removeAllObjects];
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        for (EDAMNotebook *notebook in notebooks) {
            [self getTagsForNotebook:notebook];
        }
                                }
                                failure:^(NSError *error) {
                                    NSLog(@"Failed to get tags.");
                                }];
}

- (void)getTagsForNotebook:(EDAMNotebook *)notebook {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listTagsByNotebookWithGuid:[notebook guid]
                                  success:^(NSArray *tags) {
                                      for (EDAMTag *tag in tags) {
                                          if ([tag.name isEqualToString:@"pebble"]) {
                                              [self fetchNotesWithTag:tag inNotebook:notebook];
                                          }
                                      }
                                      NSLog(@"tags: %@", tags);
                                  }
                                  failure:^(NSError *error) {
                                      NSLog(@"Failed to get tags.");
                                  }];
}

- (void)fetchNotesWithTag:(EDAMTag*)tag inNotebook:(EDAMNotebook *)notebook {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] initWithOrder:0 ascending:YES words:nil notebookGuid:notebook.guid tagGuids:[NSMutableArray arrayWithObject:tag.guid] timeZone:nil inactive:NO emphasized:nil];
    [noteStore findNotesWithFilter:filter offset:0 maxNotes:32 success:^(EDAMNoteList *list) {
        NSLog(@"list: %@", list);
        NSInteger notesToLoad = list.notes.count;
        __block NSInteger loadedNotes = 0;
        for (EDAMNote *note in list.notes) {
            [noteStore getNoteContentWithGuid:note.guid success:^(NSString *content) {
                note.content = content;
                ESChecklist *checklist = [[ESChecklist alloc] initWithNote:note];
                [self.mutableChecklists addObject:checklist];
                NSLog(@"Note content: %@ %@", content, note);
                loadedNotes++;
                if (loadedNotes >= notesToLoad) {
                    [self sortChecklistsRecent];
                    [self.delegate synchronizerUpdatedChecklists:self];
                }
            } failure:^(NSError *error) {
                NSLog(@"Error fetching note content: %@", error);
            }];
            
        }
    } failure:^(NSError *error) {
        NSLog(@"Failed to get notes.");
    }];
}

- (NSArray *)checklists {
    return self.mutableChecklists;
}

- (void)sortChecklistsRecent {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastUpdatedDate" ascending:NO];
    [self.mutableChecklists sortUsingDescriptors:@[sortDescriptor]];
}


@end
