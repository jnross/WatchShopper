//
//  ESChecklist.m
//  WatchShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklist.h"
#import "NSDate+EDAMAdditions.h"
#import "ESEvernoteSynchronizer.h"
#import "commands.h"
#import "TTTTimeIntervalFormatter.h"

@interface ESChecklist () <NSXMLParserDelegate>

@property(nonatomic,strong) NSMutableArray *elementStack;
@property(nonatomic,strong) NSMutableString *accumulatedText;
@property(nonatomic) UInt8 currentItemId;

@end

@implementation ESChecklist

- (id)initWithName:(NSString *)name guid:(NSString *)guid {
    self = [super init];
    return self;
}

- (id)initWithNote:(EDAMNote *)note {
    self = [super init];
    self.note = note;
    self.name = note.title;
    self.lastUpdatedDate = [NSDate dateWithEDAMTimestamp:note.updated.longLongValue];
    self.guid = note.guid;
    self.items = [NSMutableArray arrayWithCapacity:10];
    if (note.content != nil) {
        [self loadContent];
    }
    return self;
}


- (void)loadContent {
    NSString *content = self.note.content;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    self.elementStack = [NSMutableArray arrayWithCapacity:3];
    self.currentItemId = 0;
    [parser parse];
    self.elementStack = nil;
    self.accumulatedText = nil;
}

- (NSArray *)pebbleDataUpdates {
    NSMutableData *data = [NSMutableData data];
    NSMutableArray *updates = [NSMutableArray arrayWithObject:@{@CMD_LIST_ITEMS_START:data}];
    
    // First byte is the 1-byte list ID
    UInt8 listId = self.listId;
    [data appendBytes:&listId length:1];
    
    //Append the null-terminated list name
    const char *utf8name = self.name.UTF8String;
    [data appendBytes:utf8name length:strlen(utf8name) + 1];
    
    //Append 1-byte list item count
    UInt8 count = self.items.count;
    [data appendBytes:&count length:1];
    
    //Concatenate list items
    for (ESChecklistItem *item in self.items) {
        NSData *itemData = [item pebbleData];
        if (data.length + itemData.length > 110) {
            data = [NSMutableData data];
            [updates addObject:@{@CMD_LIST_ITEMS_CONTINUATION:data}];
        }
        [data appendData:itemData];
    }
    
    return updates;
}

- (void)saveToEvernote {
    NSMutableString *content = [NSMutableString stringWithString:@"<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note><div>"];
    for (ESChecklistItem *item in self.items) {
        if (item.isChecked) {
            [content appendFormat:@"<div><en-todo checked=\"true\"></en-todo>%@</div>", item.name];
        } else {
            [content appendFormat:@"<div><en-todo></en-todo>%@</div>", item.name];
        }
        
    }
    
    [content appendString:@"</div></en-note>"];
    self.note.content = content;
    [EVERNOTE saveNote:self.note];
}

#pragma mark - NSXMLParserDelegate implementation

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    NSString *trimmedText = [self.accumulatedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.elementStack.count < 2 && trimmedText.length > 0) {
        ESChecklistItem *item = [[ESChecklistItem alloc] initWithName:trimmedText itemId:self.currentItemId++];
        [self.items addObject:item];
        self.accumulatedText = nil;
    }
    
    NSString *stackItem = elementName;
    if ([self doesElement:elementName flagItemAsCheckedWithAttributes:attributeDict]) {
        stackItem = @"checked";
    }
    
    [self.elementStack addObject:stackItem];
    
}

- (BOOL)doesElement:(NSString *)element flagItemAsCheckedWithAttributes:(NSDictionary *)attributes {
    BOOL isSpanTag = [element isEqualToString:@"span"];
    NSString *styleString = [attributes objectForKey:@"style"];
    BOOL hasLineThroughStyle = styleString ? [styleString rangeOfString:@"line-through"].location != NSNotFound : NO;
    
    if (isSpanTag && hasLineThroughStyle) {
        return true;
    }
    
    BOOL isTodoTag = [element isEqualToString:@"en-todo"];
    NSString *checked = [attributes objectForKey:@"checked"];
    BOOL isChecked = [checked isEqualToString:@"true"];
    if (isTodoTag && isChecked) {
        return true;
    }
    return false;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    NSString *trimmedText = [self.accumulatedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length > 0) {
        ESChecklistItem *item = [[ESChecklistItem alloc] initWithName:trimmedText itemId:self.currentItemId++];
        [self.items addObject:item];
        if ([self.elementStack containsObject:@"checked"]) {
            item.isChecked = YES;
        }
        
        self.accumulatedText = nil;
    } else {
        if ([self.elementStack.lastObject isEqualToString:@"checked"]) {
            [self.elementStack removeLastObject];
            [self.elementStack removeLastObject];
            [self.elementStack addObject:@"checked"];
            [self.elementStack addObject:@"checked"];
        }
    }
    [self.elementStack removeLastObject];
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.accumulatedText == nil) {
        self.accumulatedText = [NSMutableString stringWithString:string];
    } else {
        [self.accumulatedText appendString:string];
    }
}

+ (NSString*)niceLookingStringForDate:(NSDate*) date {
    NSTimeInterval interval = [date timeIntervalSinceNow];
    
    NSTimeInterval twoDaysAgo = -60 * 60 * 24 * 2;
    NSString *dateString = nil;
    if (interval < twoDaysAgo) {
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"EEE, MMM dd, yyyy"];
        }
        dateString = [dateFormatter stringFromDate:date];
    } else {
        static TTTTimeIntervalFormatter *formatter = nil;
        if (formatter == nil) {
            formatter = [[TTTTimeIntervalFormatter alloc] init];
        }
        dateString = [formatter stringForTimeInterval:interval];
    }
    return dateString;
}

@end
