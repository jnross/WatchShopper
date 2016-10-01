//
//  Logger.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/2/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import Foundation

public func WLog(
    _ message: @autoclosure () -> String,
    file: StaticString = #file,
    line: Int = #line,
    function: StaticString = #function)
{
    NSLog("WSWS: <\(file):\(line) \(function)> \(message())")
}
