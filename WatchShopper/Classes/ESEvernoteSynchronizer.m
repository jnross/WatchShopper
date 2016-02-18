//
//  ESEvernoteSynchronizer.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/24/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESEvernoteSynchronizer.h"
#import "ENSDKAdvanced.h"
#import "ESChecklist.h"
#import "ESSettingsManager.h"
#import "commands.h"

static ESEvernoteSynchronizer *singletonInstance = nil;

@interface ESEvernoteSynchronizer ()

@property(nonatomic,strong) NSMutableArray<ESChecklist *>* gatheringChecklists;
@property(nonatomic,strong) NSMutableArray* gatheringNotebooks;

@property(nonatomic,strong) NSArray<ESChecklist *>* checklists;
@property(nonatomic,strong) NSMutableArray *observerWrappers;

@end

@interface ESEvernoteSynchronizerObserverWrapper : NSObject

@property(nonatomic,weak) NSObject<ESEvernoteSynchronizerObserver> *observer;

@end

@implementation ESEvernoteSynchronizerObserverWrapper

@end

@implementation ESEvernoteSynchronizer

+ (void)setupEvernoteSingleton {
    NSString *CONSUMER_KEY = @"jnross";
    NSString *CONSUMER_SECRET = @"[REDACTED]";
    
    // set up Evernote session singleton
    [ENSession setSharedSessionConsumerKey:CONSUMER_KEY consumerSecret:CONSUMER_SECRET optionalHost:nil];
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
    ENSession *session = [ENSession sharedSession];
    [session authenticateWithViewController:viewController preferRegistration:NO completion:^(NSError *error) {
        if (error || !session.isAuthenticated) {
            // authentication failed :(
            // show an alert, etc
            // ...
        } else {
            [self getPebbleNotes];
        } 
    }];
}

- (void)logout {
    [[ENSession sharedSession] unauthenticate];
}

- (BOOL)isAlreadyAutheticated {
    return [[ENSession sharedSession] isAuthenticated];
}

- (void)saveNote:(EDAMNote *)note {
    [[[ENSession sharedSession] primaryNoteStore] updateNote:note
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
    self.checklists = [self sortedRecentImmutableCopyOf:self.gatheringChecklists];
    self.gatheringChecklists = nil;
    self.gatheringNotebooks = nil;
    self.isGathering = NO;
    
    [self notifySynchronizerUpdatedChecklists];
}

- (void)getPebbleNotes {
    if (self.isGathering) { return; }
    self.isGathering = YES;
    [[[ENSession sharedSession] primaryNoteStore] listNotebooksWithSuccess: ^(NSArray *notebooks) {
        self.gatheringChecklists = [NSMutableArray array];
        self.gatheringNotebooks = [notebooks mutableCopy];
        NSArray *targetNotebookNames = [[ESSettingsManager sharedManager] targetNotebookNames];
        NSMutableArray *allNotebookNames = [NSMutableArray arrayWithCapacity:notebooks.count];
        self.allNotebookNames = allNotebookNames;
        for (EDAMNotebook *notebook in notebooks) {
            [allNotebookNames addObject:notebook.name];
            if ([targetNotebookNames containsObject:notebook.name] ) {
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
    ENNoteStoreClient *noteStore = [[ENSession sharedSession] primaryNoteStore];
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
    filter.order = @(2);
    filter.ascending = @NO;
    filter.notebookGuid = notebook.guid;
    filter.inactive = @NO;
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
    ENNoteStoreClient *noteStore = [[ENSession sharedSession] primaryNoteStore];
    [noteStore listTagsByNotebookWithGuid:[notebook guid] success:^(NSArray *tags) {
        NSArray *targetTags = [[ESSettingsManager sharedManager] targetTags];
        NSMutableArray *availableTargetTagGuids = [NSMutableArray arrayWithCapacity:targetTags.count];
        for (EDAMTag *tag in tags) {
            if ([targetTags containsObject:tag.name]) {
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
    ENNoteStoreClient *noteStore = [[ENSession sharedSession] primaryNoteStore];
    
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc] init];
    filter.order = @(2);
    filter.ascending = @NO;
    filter.notebookGuid = notebook.guid;
    filter.tagGuids = tagGuids;
    filter.inactive = @NO;
    [noteStore findNotesWithFilter:filter offset:0 maxNotes:32 success:^(EDAMNoteList *list) {
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
        checklist.listId = self.gatheringChecklists.count;
        [self.gatheringChecklists addObject:checklist];
    }
}

- (void)loadContentForChecklist:(ESChecklist *)checklist success:(void (^)())success failure:(void (^)(NSError* error))failure {
    NSString *guid = checklist.note.guid;
    ENNoteStoreClient *noteStore = [[ENSession sharedSession] primaryNoteStore];
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
    if ([error.domain isEqualToString:ENErrorDomain]
        && error.code == EDAMErrorCode_RATE_LIMIT_REACHED) {
        NSInteger rateLimitDurationSeconds = [error.userInfo[@"rateLimitDuration"] integerValue];
        NSInteger rateLimitDurationMinutes = rateLimitDurationSeconds / 60;
        NSString *message = [NSString stringWithFormat:@"Too many requests to Evernote.  Please try again in %ld minutes.", (long)rateLimitDurationMinutes];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
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
    NSMutableArray *updates = [NSMutableArray arrayWithObject:@{@CMD_CHECKLISTS_START:data}];
    
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
            [updates addObject:@{@CMD_CHECKLISTS_CONTINUATION:data}];
        }
        [data appendData:itemData];
        i++;
    }
    
    return updates;
}


@end
