//
//  ChecklistController.swift
//  WatchShopper
//
//  Created by Joseph Ross on 2/15/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import WatchKit

class ChecklistController: WKInterfaceController, DataProxyObserver {
    
    @IBOutlet var table:WKInterfaceTable! = nil
    var list:ListWithItems? = nil
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        DataProxy.defaultProxy.addDataProxyObserver(self)
        if let list = context as? ListWithItems {
            self.list = list
        } else if let listInfo = context as? ListInfo {
            DataProxy.defaultProxy.fetchListItems(listInfo.guid, completionHandler: { list in
                self.list = list
                self.refreshData()
            })
        } else {
            DataProxy.defaultProxy.sendNeedsUpdate()
        }
    }
    
    func dataProxyUpdatedLists(_ dataProxy: DataProxy) {
        
    }
    
    func dataProxyUpdatedLatestList(_ dataProxy: DataProxy, latest: ListWithItems) {
        if self.list == nil {
            self.list = latest
            refreshData()
        }
    }
    
    func refreshData() {
        self.setTitle(list?.name)
        refreshTable()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func willActivate() {
        super.willActivate()
        if self.list == nil {
            DataProxy.defaultProxy.sendNeedsUpdate()
        } else {
            refreshData()
        }
    }
    
    func refreshTable() {
        table.setNumberOfRows(list?.items.count ?? 0, withRowType: "ItemRow")
        
        for (index, item) in (list?.items ?? []).enumerated() {
            if let row = table.rowController(at: index) as? ItemRow {
                row.nameLabel.setText(item.name)
                row.checked = item.checked
                setCheckedImage(row)
                row.itemId = item.id
            }
        }
    }
    
    func setCheckedImage(_ row:ItemRow) {
        if row.checked {
            row.checkButton.setBackgroundImageNamed("checked")
        } else {
            row.checkButton.setBackgroundImageNamed("unchecked")
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if let row = table.rowController(at: rowIndex) as? ItemRow, let listGuid = list?.guid {
            row.checked = !row.checked
            list?.items[rowIndex].checked = row.checked
            setCheckedImage(row)
            DataProxy.defaultProxy.updateCheckedItem(row.itemId, listGuid: listGuid, checked: row.checked)
        }
    }
    
    // MARK: Menu actions
    
    @IBAction func doRefreshAction() {
        guard let guid = self.list?.guid else {
            fatalError("List must not be nil at this point, and must have a guid.")
        }
        DataProxy.defaultProxy.fetchListItems(guid) { (list) -> Void in
            self.list = list
            self.refreshData()
        }
    }
    
    @IBAction func doSaveAction() {
        guard let list = self.list else { return }
        DataProxy.defaultProxy.saveList(list)
    }
}

class ItemRow : NSObject {
    @IBOutlet var checkButton:WKInterfaceButton! = nil
    @IBOutlet var nameLabel:WKInterfaceLabel! = nil
    var checked:Bool = false
    var itemId:Int = -1
}
