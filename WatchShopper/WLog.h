//
//  WLog.h
//  WatchShopper
//
//  Created by Joseph Ross on 10/2/16.
//  Copyright © 2016 Joseph Ross. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WLog( s, ... ) NSLog( @"WSWS<%@:%d %s> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __FUNCTION__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
