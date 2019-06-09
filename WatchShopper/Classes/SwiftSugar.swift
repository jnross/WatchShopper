
//
//  SwiftSugar.swift
//  WatchShopper
//
//  Created by Joseph Ross on 6/9/19.
//  Copyright © 2019 Easy Street 3. All rights reserved.
//

import Foundation

extension Collection {
    var isNotEmpty: Bool {
        return isEmpty == false
    }
}

@objc extension UIRefreshControl {
    @objc func programaticallyBeginRefreshing(in tableView: UITableView) {
        beginRefreshing()
        let offsetPoint = CGPoint.init(x: 0, y: -frame.size.height)
        tableView.setContentOffset(offsetPoint, animated: true)
    }
}
