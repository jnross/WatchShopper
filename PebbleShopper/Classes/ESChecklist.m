//
//  ESChecklist.m
//  PebbleShopper
//
//  Created by Joseph Ross on 11/26/13.
//  Copyright (c) 2013 Easy Street 3. All rights reserved.
//

#import "ESChecklist.h"
#import "NSDate+EDAMAdditions.h"

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
    self.name = note.title;
    self.lastUpdatedDate = [NSDate endateFromEDAMTimestamp:note.updated];
    self.guid = note.guid;
    self.items = [NSMutableArray arrayWithCapacity:10];
    NSString *content = note.content;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    self.elementStack = [NSMutableArray arrayWithCapacity:3];
    self.currentItemId = 0;
    [parser parse];
    self.elementStack = nil;
    self.accumulatedText = nil;
    return self;
}

- (NSArray *)pebbleDataUpdates {
    NSMutableData *data = [NSMutableData data];
    NSMutableArray *updates = [NSMutableArray arrayWithObject:@{@0:data}];
    
    // First byte is the 1-byte list ID
    UInt8 listId = 0;
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
            [updates addObject:@{@2:data}];
        }
        [data appendData:itemData];
    }
    
    return updates;
}

#pragma mark - NSXMLParserDelegate implementation

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
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
    
    BOOL flagAsChecked = isSpanTag
                        && hasLineThroughStyle;
    return flagAsChecked;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (self.accumulatedText != nil) {
        ESChecklistItem *item = [[ESChecklistItem alloc] initWithName:self.accumulatedText itemId:self.currentItemId++];
        [self.items addObject:item];
        if ([self.elementStack containsObject:@"checked"]) {
            item.isChecked = YES;
        }
        
        self.accumulatedText = nil;
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


@end
