//
//  ListsController.swift
//  WatchApp Extension
//
//  Created by Joseph Ross on 2/13/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import WatchKit
import Foundation


class ListsController: WKInterfaceController, DataProxyObserver {

    @IBOutlet weak var table:WKInterfaceTable! = nil
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        DataProxy.defaultProxy.addDataProxyObserver(self)
        DataProxy.defaultProxy.sendNeedsUpdate()
        refreshData()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        DataProxy.defaultProxy.removeDataProxyObserver(self)
    }
    
    func dataProxyUpdatedLists(dataProxy: DataProxy) {
        refreshData()
    }
    
    func refreshData() {
        let lists = DataProxy.defaultProxy.lists
        table.setNumberOfRows(lists.count, withRowType: "ListRow")
        for (index, listInfo) in lists.enumerate() {
            if let listRow = table.rowControllerAtIndex(index) as? ListRow {
                listRow.nameLabel.setText(listInfo.name)
                listRow.dateLabel.setText(listInfo.date)
                listRow.listGuid = listInfo.guid
            }
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if let row = table.rowControllerAtIndex(rowIndex) {
            DataProxy.defaultProxy.fetchListItems(row.listGuid) { list -> Void in
                self.pushControllerWithName("Checklist", context: list)
            }
        }
    }

}

class ListRow : NSObject {
    @IBOutlet weak var nameLabel:WKInterfaceLabel! = nil
    @IBOutlet weak var dateLabel:WKInterfaceLabel! = nil
    var listGuid:String = ""
}
