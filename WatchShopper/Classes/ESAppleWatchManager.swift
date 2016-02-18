//
//  ESAppleWatchManager.swift
//  WatchShopper
//
//  Created by Joseph Ross on 2/14/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import UIKit
import WatchConnectivity

@available (iOS 9.0, *)
class ESAppleWatchManager: NSObject, WCSessionDelegate, ESEvernoteSynchronizerObserver {
    static let defaultManager = ESAppleWatchManager()
    
    let session = WCSession.defaultSession()
    
    func start() {
        session.delegate = self
        session.activateSession()
        ESEvernoteSynchronizer.sharedSynchronizer().addObserver(self)
    }
    
    
    func sessionWatchStateDidChange(session: WCSession) {
        
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let action = message["action"] as? String {
            switch action {
            case "needsUpdate":
                let synchronizer = ESEvernoteSynchronizer.sharedSynchronizer()
                if synchronizer.checklists()?.count ?? 0 == 0 && synchronizer.isAlreadyAutheticated(){
                    ESEvernoteSynchronizer.sharedSynchronizer().getPebbleNotes()
                } else {
                    sendListInfo()
                }
                replyHandler([:])
            case "fetchListItems":
                fetchListWithItems(message, completion:replyHandler)
                
            case "updateCheckedItem":
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.updateCheckedItem(message)
                })
                replyHandler([:])
            default:
                break
            }
        }
    }
    
    func updateCheckedItem(message:[String:AnyObject]) {
        if let listGuid = message["listGuid"] as? String,
            itemId = message["itemId"] as? Int,
            checked = message["checked"] as? Bool {
                for list in ESEvernoteSynchronizer.sharedSynchronizer().checklists() {
                    if list.guid == listGuid && list.items.count > itemId {
                        if let item = list.items[itemId] as? ESChecklistItem {
                            item.isChecked = checked
                            list.observer?.checklist(list, updatedItem: item)
                        }
                        break
                    }
                }
        }
    }
    
    func fetchListWithItems(message:[String:AnyObject], completion:[String:AnyObject] -> Void) {
        if let guid = message["guid"] as? String {
            for list in ESEvernoteSynchronizer.sharedSynchronizer().checklists() {
                if list.guid == guid {
                    if list.items.count == 0 {
                        ESEvernoteSynchronizer.sharedSynchronizer().loadContentForChecklist(list, success: { () -> Void in
                            self.finishReturningList(list, completion: completion)
                            }, failure: { (error) -> Void in
                                
                        })
                    } else {
                        finishReturningList(list, completion: completion)
                    }
                    
                    break
                }
            }
        }
    }
    
    func finishReturningList(list:ESChecklist, completion:[String:AnyObject] -> Void) {
        let items = list.items.map() { item -> [String:AnyObject] in
            return ["name":item.name, "id":Int(item.itemId), "checked":item.isChecked]
        }
        
        if let name = list.name,
            let date = ESChecklist.niceLookingStringForDate(list.lastUpdatedDate) {
                completion(["name":name, "date":date, "guid":list.guid, "items":items])
        }
    }
    
    func synchronizerUpdatedChecklists(synchronizer: ESEvernoteSynchronizer!) {
        NSLog("!!!!!!!!!!!!!!!!!!!!!!!!!!! updated checklists")
        sendListInfo()
    }
    
    func sendListInfo() {
        let lists = ESEvernoteSynchronizer.sharedSynchronizer().checklists()
        var listDicts:[[String:AnyObject]] = []
        for list in lists {
            if let name = list.name,
                let date = ESChecklist.niceLookingStringForDate(list.lastUpdatedDate) {
                    listDicts.append(["name":name, "date":date, "guid":list.guid])
            }
        }
        do {
            try session.updateApplicationContext(["lists":listDicts])
        } catch  {
            print("Failed to update application context")
        }
    }
}
