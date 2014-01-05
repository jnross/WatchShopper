//
//  ESEvernoteSynchronizer.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESEvernoteSynchronizer.h"
#import "EvernoteSDK.h"
#import "ESChecklist.h"

static ESEvernoteSynchronizer *singletonInstance = nil;

@interface ESEvernoteSynchronizer ()

@property(nonatomic,strong) NSMutableArray* gatheringChecklists;
@property(nonatomic,strong) NSMutableArray* gatheringNotebooks;

@property(nonatomic,strong) NSArray* checklists;
@property(nonatomic,strong) NSMutableArray *observerWrappers;
@property(nonatomic,strong) NSArray *targetTags;
@property(nonatomic,strong) NSArray *targetNotebookNames;

@end

@interface ESEvernoteSynchronizerObserverWrapper : NSObject

@property(nonatomic,weak) NSObject<ESEvernoteSynchronizerObserver> *observer;

@end

@implementation ESEvernoteSynchronizerObserverWrapper

@end

@implementation ESEvernoteSynchronizer

+ (void)setupEvernoteSingleton {
    NSString *EVERNOTE_HOST = BootstrapServerBaseURLStringSandbox;
    NSString *CONSUMER_KEY = @"jnross";
    NSString *CONSUMER_SECRET = @"[REDACTED]";
    
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
    self.observerWrappers = [NSMutableArray array];
    
    self.targetTags = @[@"pebble"];
    self.targetNotebookNames = @[@"Pebble"];
    
    
    return self;
}

- (void)addObserver:(NSObject<ESEvernoteSynchronizerObserver> *)observer {
    ESEvernoteSynchronizerObserverWrapper *wrapper = [ESEvernoteSynchronizerObserverWrapper new];
    wrapper.observer = observer;
    [self.observerWrappers addObject:wrapper];
}

- (void)removeObserver:(NSObject<ESEvernoteSynchronizerObserver> *)observer {
    ESEvernoteSynchronizerObserverWrapper *toRemove = nil;
    for (ESEvernoteSynchronizerObserverWrapper *wrapper in self.observerWrappers) {
        if (wrapper.observer == observer) {
            toRemove = wrapper;
            break;
        }
    }
    if (toRemove != nil) {
        [self.observerWrappers removeObject:toRemove];
    }
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
                                          [self handleError:error];
                                      }];
}

- (void)finishNotebook:(EDAMNotebook*)notebook {
    [self.gatheringNotebooks removeObject:notebook];
    if (self.gatheringNotebooks.count == 0) {
        [self finishAllNotebooks];
    }
}

- (void)finishAllNotebooks {
    if (self.gatheringChecklists.count > 0) {
        self.checklists = [self sortedRecentImmutableCopyOf:self.gatheringChecklists];
    }
    self.gatheringChecklists = nil;
    self.gatheringNotebooks = nil;
    
    [self notifySynchronizerUpdatedChecklists];
}

- (void)getPebbleNotes {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess: ^(NSArray *notebooks) {
        self.gatheringChecklists = [NSMutableArray array];
        self.gatheringNotebooks = [notebooks mutableCopy];
        for (EDAMNotebook *notebook in notebooks) {
            if ([self.targetNotebookNames containsObject:notebook.name] ) {
                [self getAllNotesForNotebook:notebook];
            } else {
                [self getTagsForNotebook:notebook];
            }
        }
    }
    failure:^(NSError *error) {
        NSLog(@"Failed to get notebooks.");
        [self handleError:error];
        [self finishAllNotebooks];
        
    }];
}

- (void)getAllNotesForNotebook:(EDAMNotebook *) notebook {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] initWithOrder:0 ascending:YES words:nil notebookGuid:notebook.guid tagGuids:nil timeZone:nil inactive:NO emphasized:nil];
    [noteStore findNotesWithFilter:filter offset:0 maxNotes:32 success:^(EDAMNoteList *list) {
        NSLog(@"list: %@", list);
        [self gatherChecklistsFromNotes:list.notes];
        [self finishNotebook:notebook];
    } failure:^(NSError *error) {
        NSLog(@"Failed to get notes.");
        [self handleError:error];
        [self finishNotebook:notebook];
    }];
    
}

- (void)getTagsForNotebook:(EDAMNotebook *)notebook {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listTagsByNotebookWithGuid:[notebook guid] success:^(NSArray *tags) {
        NSMutableArray *availableTargetTagGuids = [NSMutableArray arrayWithCapacity:self.targetTags.count];
        for (EDAMTag *tag in tags) {
            if ([self.targetTags containsObject:tag.name]) {
                [availableTargetTagGuids addObject:tag.guid];
            }
        }
        if (availableTargetTagGuids.count > 0) {
            [self fetchNotesWithTagGuids:availableTargetTagGuids inNotebook:notebook];
        } else {
            [self finishNotebook:notebook];
        }
        NSLog(@"tags: %@", tags);
    }
    failure:^(NSError *error) {
        NSLog(@"Failed to get tags.");
        [self handleError:error];
        [self finishNotebook:notebook];
    }];
}

- (void)fetchNotesWithTagGuids:(NSMutableArray*)tagGuids inNotebook:(EDAMNotebook *)notebook {
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] initWithOrder:0 ascending:YES words:nil notebookGuid:notebook.guid tagGuids:tagGuids timeZone:nil inactive:NO emphasized:nil];
    [noteStore findNotesWithFilter:filter offset:0 maxNotes:32 success:^(EDAMNoteList *list) {
        NSLog(@"list: %@", list);
        [self gatherChecklistsFromNotes:list.notes];
        [self finishNotebook:notebook];
    } failure:^(NSError *error) {
        NSLog(@"Failed to get notes.");
        [self handleError:error];
        [self finishNotebook:notebook];
    }];
}

- (void)gatherChecklistsFromNotes:(NSArray *)notes {
    for (EDAMNote *note in notes) {
        ESChecklist *checklist = [[ESChecklist alloc] initWithNote:note];
        [self.gatheringChecklists addObject:checklist];
    }
}

- (void)loadContentForChecklist:(ESChecklist *)checklist success:(void (^)())success failure:(void (^)(NSError* error))failure {
    NSString *guid = checklist.note.guid;
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore getNoteContentWithGuid:guid success:^(NSString *content) {
        checklist.note.content = content;
        [checklist loadContent];
        NSLog(@"Note content: %@ %@", content, checklist.note);
        success();
    } failure:^(NSError *error) {
        NSLog(@"Error fetching note content: %@", error);
        [self handleError:error];
        failure(error);
    }];
}

- (void)notifySynchronizerUpdatedChecklists {
    NSArray *wrappers = [NSArray arrayWithArray:self.observerWrappers];
    for (ESEvernoteSynchronizerObserverWrapper *wrapper in wrappers) {
        [wrapper.observer synchronizerUpdatedChecklists:self];
    }
}

- (void) handleError:(NSError *)error {
    if (error == nil) {
        return;
    }
    if ([error.domain isEqualToString:EvernoteSDKErrorDomain]
        && error.code == EDAMErrorCode_RATE_LIMIT_REACHED) {
        NSInteger rateLimitDurationSeconds = [error.userInfo[@"rateLimitDuration"] integerValue];
        NSInteger rateLimitDurationMinutes = rateLimitDurationSeconds / 60;
        NSString *message = [NSString stringWithFormat:@"Too many requests to Evernote.  Please try again in %ld minutes.", (long)rateLimitDurationMinutes];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (NSArray *)sortedRecentImmutableCopyOf:(NSMutableArray *)toSort {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastUpdatedDate" ascending:NO];
    return [toSort sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (NSData *)pebbleDataForListName:(NSString *)listName index:(NSUInteger)index {
    const char *utf8name = listName.UTF8String;
    unsigned long nameLength = strlen(utf8name);
    NSMutableData *data = [NSMutableData dataWithCapacity:nameLength + 3];
    UInt8 itemId = index;
    [data appendBytes:&itemId length:1];
    [data appendBytes:utf8name length:nameLength + 1];
    UInt8 flags = 0;
    [data appendBytes:&flags length:1];
    return data;
}

- (NSArray *)checklistDataUpdates {
    NSMutableData *data = [NSMutableData data];
    NSMutableArray *updates = [NSMutableArray arrayWithObject:@{@3:data}];
    
    // First byte is the 1-byte list ID
    UInt8 listId = 0;
    [data appendBytes:&listId length:1];
    
    //Append the null-terminated list name
    const char *utf8name = @"Lists".UTF8String;
    [data appendBytes:utf8name length:strlen(utf8name) + 1];
    
    //Append 1-byte list item count
    UInt8 count = self.checklists.count;
    [data appendBytes:&count length:1];
    
    //Concatenate list items
    int i = 0;
    for (ESChecklist *aList in self.checklists) {
        NSData *itemData = [self pebbleDataForListName:aList.name index:i];
        if (data.length + itemData.length > 110) {
            data = [NSMutableData data];
            [updates addObject:@{@4:data}];
        }
        [data appendData:itemData];
        i++;
    }
    
    return updates;
}


@end
