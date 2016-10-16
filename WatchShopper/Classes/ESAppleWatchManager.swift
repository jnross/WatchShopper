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
class AppleWatchManager: NSObject, WCSessionDelegate, EvernoteSynchronizerObserver {
    static let defaultManager = AppleWatchManager()
    var checklists:[ESChecklist] = []
    
    let session = WCSession.default()
    
    func start() {
        session.delegate = self
        session.activate()
        EvernoteSynchronizer.shared.addObserver(self)
    }
    
    enum WatchAction : String {
        case needsUpdate
        case fetchLists
        case fetchListItems
        case updateCheckedItem
    }
    
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionWatchStateDidChange(_ session: WCSession) {}
    func sessionReachabilityDidChange(_ session: WCSession) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let action = WatchAction(rawValue:message["action"] as? String ?? "") {
            switch action {
            case .fetchListItems:
                fetchListWithItems(message, completion:replyHandler)
            default:
                break
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let action = WatchAction(rawValue:message["action"] as? String ?? "") {
            switch action {
            case .needsUpdate:
                WLog("Got update request")
                sendLatestList()
            case .fetchLists:
                sendListOfLists()
            case .updateCheckedItem:
                OperationQueue.main.addOperation({ () -> Void in
                    self.updateCheckedItem(message)
                })
            default:
                break
            }
        }
    }
    
    func updateCheckedItem(_ message:[String:Any]) {
        if let listGuid = message["listGuid"] as? String,
            let itemId = message["itemId"] as? Int,
            let checked = message["checked"] as? Bool {
                for list in checklists {
                    if list.guid == listGuid && list.items().count > itemId {
                        let item = list.items()[itemId]
                        item.isChecked = checked
                        list.observer?.checklist(list, updatedItem: item)
                        
                        break
                    }
                }
        }
    }
    
    func fetchListWithItems(_ message:[String:Any], completion:@escaping ([String:Any]) -> Void) {
        
        guard let guid = message["guid"] as? String else {
            fatalError("Received list fetch request without a guid.")
        }
        WLog("Got request from watch for list \(guid)")
        for list in checklists {
            if list.guid == guid {
                EvernoteSynchronizer.shared.loadContent(for: list, success: { () -> Void in
                    self.finishReturningList(list, completion: completion)
                    }, failure: { (error) -> Void in
                        WLog("Error loading list \(guid): \(error)")
                })
                
                break
            }
        }
    }
    
    func finishReturningList(_ list:ESChecklist, completion:([String:Any]) -> Void) {
        completion(serializeable(for: list))
    }
    
    func serializeable(for list:ESChecklist) -> [String:Any] {
        let items = list.items().map() { item -> [String:Any] in
            return ["name":item.name, "id":Int(item.itemId), "checked":item.isChecked]
        }
        
        var ret:[String:Any] = ["name":list.name, "guid":list.guid, "items":items]
        if let date = ESChecklist.niceLookingString(for: list.lastUpdatedDate) {
            ret["date"] = date
        }
        return ret
    }
    
    func sendLatestList() {
        let lists = checklists
        if lists.count == 0 {
            EvernoteSynchronizer.shared.refreshWatchNotes()
            return
        }
        
        //TODO: Add a check that if the latest list has not loaded its items, load them.
        
        let latestList = lists[0]
        if latestList.note?.content == nil {
            EvernoteSynchronizer.shared.loadContent(for: latestList, success: {
                    self.sendLatestList()
                }, failure: { (error) in
                    NSLog("Failed to load latest list: \(error)")
            })
            return
        }
        do {
            try session.updateApplicationContext(["latest":serializeable(for: latestList)])
        } catch  {
            print("Failed to update application context")
        }
    }
    
    func synchronizer(_ synchronizer: EvernoteSynchronizer, updatedChecklists:[ESChecklist]) {
        NSLog("!!!!!!!!!!!!!!!!!!!!!!!!!!! updated checklists")
        self.checklists = updatedChecklists
        sendListOfLists()
       
        // TODO: Don't send latest list if the contents aren't loaded.
        sendLatestList()
    }
    
    func sendListOfLists() {
        let lists = checklists
        if lists.count == 0 {
            EvernoteSynchronizer.shared.refreshWatchNotes()
            return
        }
        
        var listDicts:[[String:Any]] = []
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
