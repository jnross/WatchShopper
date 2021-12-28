//
//  SwiftUI+Extensions.swift
//  WatchShopper
//
//  Created by Joseph Ross on 11/28/21.
//

import SwiftUI

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
