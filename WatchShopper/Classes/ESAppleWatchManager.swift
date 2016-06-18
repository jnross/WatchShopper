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
    
    let session = WCSession.default()
    
    func start() {
        session.delegate = self
        session.activate()
        ESEvernoteSynchronizer.shared().add(self)
    }
    
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {}
    func sessionWatchStateDidChange(_ session: WCSession) {}
    func sessionReachabilityDidChange(_ session: WCSession) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let action = message["action"] as? String {
            switch action {
            case "needsUpdate":
                let synchronizer = ESEvernoteSynchronizer.shared()
                if synchronizer.checklists().count ?? 0 == 0 && synchronizer.isAlreadyAutheticated()
                {
                    ESEvernoteSynchronizer.shared().getPebbleNotes()
                } else {
                    sendListInfo()
                }
                replyHandler([:])
            case "fetchListItems":
                fetchListWithItems(message, completion:replyHandler)
                
            case "updateCheckedItem":
                OperationQueue.main().addOperation({ () -> Void in
                    self.updateCheckedItem(message)
                })
                replyHandler([:])
            default:
                break
            }
        }
    }
    
    func updateCheckedItem(_ message:[String:AnyObject]) {
        if let listGuid = message["listGuid"] as? String,
            itemId = message["itemId"] as? Int,
            checked = message["checked"] as? Bool {
                for list in ESEvernoteSynchronizer.shared().checklists() {
                    if list.guid == listGuid && list.items().count > itemId {
                        let item = list.items()[itemId]
                        item.isChecked = checked
                        list.observer?.checklist(list, updatedItem: item)
                        
                        break
                    }
                }
        }
    }
    
    func fetchListWithItems(_ message:[String:AnyObject], completion:([String:AnyObject]) -> Void) {
        if let guid = message["guid"] as? String {
            for list in ESEvernoteSynchronizer.shared().checklists() {
                if list.guid == guid {
                    if list.items().count == 0 {
                        ESEvernoteSynchronizer.shared().loadContent(for: list, success: { () -> Void in
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
    
    func finishReturningList(_ list:ESChecklist, completion:([String:AnyObject]) -> Void) {
        let items = list.items().map() { item -> [String:AnyObject] in
            return ["name":item.name, "id":Int(item.itemId), "checked":item.isChecked]
        }
        
        if let date = ESChecklist.niceLookingString(for: list.lastUpdatedDate) {
                completion(["name":list.name, "date":date, "guid":list.guid, "items":items])
        }
    }
    
    func synchronizerUpdatedChecklists(_ synchronizer: ESEvernoteSynchronizer) {
        NSLog("!!!!!!!!!!!!!!!!!!!!!!!!!!! updated checklists")
        sendListInfo()
    }
    
    func sendListInfo() {
        let lists = ESEvernoteSynchronizer.shared().checklists()
        var listDicts:[[String:AnyObject]] = []
        for list in lists {
            if let date = ESChecklist.niceLookingString(for: list.lastUpdatedDate) {
                    listDicts.append(["name":list.name, "date":date, "guid":list.guid])
            }
        }
        do {
            try session.updateApplicationContext(["lists":listDicts])
        } catch  {
            print("Failed to update application context")
        }
    }
}
