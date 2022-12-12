//
//  SwiftExtensions.swift
//  WatchShopper
//
//  Created by Joseph Ross on 12/12/22.
//

import Foundation


infix operator ??? : NilCoalescingPrecedence

func ???(lhs: Any?, rhs: String) -> String {
    if let lhs = lhs {
        return "\(lhs)"
    } else {
        return rhs
    }
}
