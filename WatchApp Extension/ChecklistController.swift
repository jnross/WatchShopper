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
    var reorderTimer:Timer? = nil
    var reorderIndices:Set<Int> = Set<Int>()
    
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
        sortCheckedItemsToBottom()
        refreshTable()
    }
    
    func sortCheckedItemsToBottom() {
        if let list = list {
            list.items = list.items.sorted(by: { (first, second) in
                if first.checked != second.checked {
                    return !first.checked
                } else {
                    return first.id < second.id
                }
            })
        }
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
        guard let list = list else { return }
        table.setNumberOfRows(list.items.count, withRowType: "ItemRow")
        
        for (index, item) in (list.items).enumerated() {
            setupRow(at: index, item: item)
        }
    }
    
    func setupRow(at index:Int, item:ListItem) {
        if let row = table.rowController(at: index) as? ItemRow {
            row.nameLabel.setText(item.name)
            row.checked = item.checked
            setCheckedImage(row)
            row.itemId = item.id
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
            reorderIndices.insert(rowIndex)
            resetReorderTimer()
            row.checked = !row.checked
            list?.items[rowIndex].checked = row.checked
            setCheckedImage(row)
            DataProxy.defaultProxy.updateCheckedItem(row.itemId, listGuid: listGuid, checked: row.checked)
        }
    }
    
    func resetReorderTimer() {
        cancelReorderTimer()
        reorderTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
            self.cancelReorderTimer()
            self.reorderTable()
        })
    }
    
    func cancelReorderTimer() {
        reorderTimer?.invalidate()
        reorderTimer = nil
    }
    
    func reorderTable() {
        guard let list = list else { return }
        var reorderIds:[Int] = []
        for i in reorderIndices {
            let item = list.items[i]
            reorderIds.append(item.id)
        }
        sortCheckedItemsToBottom()
        var insertIndices:[Int] = []
        for (i,item) in list.items.enumerated() {
            if reorderIds.contains(item.id) {
                insertIndices.append(i)
            }
        }
        
        table.removeRows(at: IndexSet(Array(reorderIndices)))
        table.insertRows(at: IndexSet(insertIndices), withRowType: "ItemRow")
        for index in insertIndices {
            let item = list.items[index]
            setupRow(at: index, item: item)
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
