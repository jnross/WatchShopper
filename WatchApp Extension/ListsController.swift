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
    
    
    // MARK: Controller lifecycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
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
    
    // MARK: DataProxyObserver
    func dataProxyUpdatedLists(_ dataProxy: DataProxy) {
        refreshData()
    }
    
    func dataProxyUpdatedLatestList(_ dataProxy: DataProxy, latest: ListWithItems) {
        if dataProxy.state == .JustLaunched {
            self.pushController(withName: "Checklist", context: latest)
        }
    }
    
    func refreshData() {
        let lists = DataProxy.defaultProxy.lists
        table.setNumberOfRows(lists.count, withRowType: "ListRow")
        for (index, listInfo) in lists.enumerated() {
            if let listRow = table.rowController(at: index) as? ListRow {
                listRow.nameLabel.setText(listInfo.name)
                listRow.dateLabel.setText(listInfo.date)
                listRow.listGuid = listInfo.guid
            }
        }
    }
    
    // MARK: WKInterfaceTableDelegate
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if let row = table.rowController(at: rowIndex) {
            DataProxy.defaultProxy.fetchListItems((row as AnyObject).listGuid) { list -> Void in
                self.pushController(withName: "Checklist", context: list)
            }
        }
    }
    
    // MARK: Menu actions
    
    @IBAction func doRefreshAction() {
        DataProxy.defaultProxy.sendNeedsUpdate()
    }

}

class ListRow : NSObject {
    @IBOutlet weak var nameLabel:WKInterfaceLabel! = nil
    @IBOutlet weak var dateLabel:WKInterfaceLabel! = nil
    var listGuid:String = ""
}
