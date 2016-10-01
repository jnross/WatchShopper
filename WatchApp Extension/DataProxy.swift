//
//  DataProxy.swift
//  WatchShopper
//
//  Created by Joseph Ross on 2/14/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import WatchKit
import WatchConnectivity

protocol DataProxyObserver: NSObjectProtocol {
    func dataProxyUpdatedLists(_ dataProxy:DataProxy)
    func dataProxyUpdatedLatestList(_ dataProxy:DataProxy, latest:ListWithItems)
}
enum WatchAppState {
    case JustLaunched
    case BackedOutToTopList
    case UserSelectedList
    case Unauthenticated
    case ApiLimitReached
    
}

class DataProxy: NSObject, WCSessionDelegate {
    static let defaultProxy = DataProxy()
    
    let session = WCSession.default()
    
    var lists:[ListInfo] = []
    var latest:ListInfo? = nil
    
    var observers:[DataProxyObserver] = []
    
    var state:WatchAppState = .JustLaunched
    
    func start() {
        session.delegate = self
        session.activate()
    }
    
    func sendNeedsUpdate() {
        WLog("Sent update request")
        session.sendMessage(["action":"needsUpdate"], replyHandler: nil) { (error) -> Void in
            WLog("Error requesting update: \(error)")
        }
    }
    
    func fetchListItems(_ guid:String, completionHandler:@escaping (ListWithItems) -> Void) {
        session.sendMessage(["action":"fetchListItems", "guid":guid], replyHandler: { (reply) -> Void in
            if let list = ListWithItems(dictionary: reply) {
                WLog("Got \(list.items.count) items for list \(list.guid)")
                completionHandler(list)
            }
            }) { (error) -> Void in
                WLog("Got error while fetching list \(guid): \(error)")
        }
        WLog("Requested items for list \(guid)")
    }
    
    func updateCheckedItem(_ itemId:Int, listGuid:String, checked:Bool) {
        session.sendMessage(["action":"updateCheckedItem", "listGuid":listGuid, "itemId":itemId, "checked":checked], replyHandler:nil, errorHandler:nil)
    }
    
    func addDataProxyObserver(_ observer:DataProxyObserver) {
        observers.append(observer)
    }
    
    func removeDataProxyObserver(_ observer:DataProxyObserver) {
        if let index = observers.index(where: {return $0.isEqual(observer)}) {
            observers.remove(at: index)
        }
    }
    
    func notifyUpdatedLists() {
        observers.forEach({$0.dataProxyUpdatedLists(self)})
    }
    
    func notifyLatestList(_ listInfo:ListWithItems) {
        observers.forEach({$0.dataProxyUpdatedLatestList(self, latest: listInfo)})
    }
    
    // MARK: WCSessionDelegate methods
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let listDicts = applicationContext["lists"] as? [[String:AnyObject]] {
            lists = []
            for listDict in listDicts {
                if let list = ListInfo(dictionary: listDict) {
                    lists.append(list)
                }
            }
            notifyUpdatedLists()
        } else if let latestList = applicationContext["latest"] as? [String:AnyObject] {
            if let list = ListWithItems(dictionary: latestList) {
                latest = list
                notifyLatestList(list)
            }
            
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
    }
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        
    }
}

class ListInfo {
    let name:String
    let date:String
    let guid:String
    
    init(name:String, date:String, guid:String) {
        self.name = name
        self.date = date
        self.guid = guid
    }
    
    init?(dictionary:[String:Any]) {
        name = dictionary["name"] as? String ?? ""
        date = dictionary["date"] as? String ?? ""
        guid = dictionary["guid"] as? String ?? ""
        if name == "" || guid == "" {
            return nil
        }
    }
}

class ListItem {
    var name:String = ""
    var id:Int = -1
    var checked:Bool = false
}

class ListWithItems : ListInfo {
    let items:[ListItem]
    init(name:String, date:String, guid:String, items:[ListItem]) {
        self.items = items
        super.init(name:name, date:date, guid:guid)
    }
    
    override init?(dictionary:[String:Any]) {
        var items:[ListItem]? = nil
        if let itemDicts = dictionary["items"] as? [[String: Any]] {
            items = itemDicts.map() { itemDict -> ListItem in
                let item = ListItem()
                item.name = itemDict["name"] as? String ?? ""
                item.id = itemDict["id"] as? Int ?? -1
                item.checked = itemDict["checked"] as? Bool ?? false
                return item
            }
        }
        self.items =  items ?? []
        super.init(dictionary: dictionary)
    }
}
