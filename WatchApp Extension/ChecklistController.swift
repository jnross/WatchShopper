//
//  ChecklistController.swift
//  WatchShopper
//
//  Created by Joseph Ross on 2/15/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import WatchKit

class ChecklistController: WKInterfaceController {
    
    @IBOutlet var table:WKInterfaceTable! = nil
    var list:ListWithItems? = nil
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        list = context as? ListWithItems
        self.setTitle(list?.name)
        refreshTable()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    func refreshTable() {
        table.setNumberOfRows(list?.items.count ?? 0, withRowType: "ItemRow")
        
        for (index, item) in (list?.items ?? []).enumerate() {
            if let row = table.rowControllerAtIndex(index) as? ItemRow {
                row.nameLabel.setText(item.name)
                row.checked = item.checked
                setCheckedImage(row)
                row.itemId = item.id
            }
        }
    }
    
    func setCheckedImage(row:ItemRow) {
        if row.checked {
            row.checkButton.setBackgroundImageNamed("checked")
        } else {
            row.checkButton.setBackgroundImageNamed("unchecked")
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if let row = table.rowControllerAtIndex(rowIndex) as? ItemRow, listGuid = list?.guid {
            row.checked = !row.checked
            setCheckedImage(row)
            DataProxy.defaultProxy.updateCheckedItem(row.itemId, listGuid: listGuid, checked: row.checked)
        }
    }
    
}

class ItemRow : NSObject {
    @IBOutlet var checkButton:WKInterfaceButton! = nil
    @IBOutlet var nameLabel:WKInterfaceLabel! = nil
    var checked:Bool = false
    var itemId:Int = -1
}
