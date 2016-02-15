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
    func dataProxyUpdatedLists(dataProxy:DataProxy)
}

class DataProxy: NSObject, WCSessionDelegate {
    static let defaultProxy = DataProxy()
    
    let session = WCSession.defaultSession()
    
    var lists:[ListInfo] = []
    
    var observers:[DataProxyObserver] = []
    
    func start() {
        session.delegate = self
        session.activateSession()
    }
    
    func sendNeedsUpdate() {
        session.sendMessage(["action":"needsUpdate"], replyHandler: { (reply) -> Void in
            NSLog("!!!!!!!!!!!!!!!!!!Got reply: %@", reply)
            }) { (error) -> Void in
            NSLog("!!!!!!!!!!!!!!!!!Got error: %@", error)
        }
    }
    
    func fetchListItems(guid:String, completionHandler:ListWithItems -> Void) {
        session.sendMessage(["action":"fetchListItems", "guid":guid], replyHandler: { (reply) -> Void in
            if let list = ListWithItems(dictionary: reply) {
                completionHandler(list)
            }
            }) { (error) -> Void in
                NSLog("!!!!!!!!!!!!!!!!!Got error: %@", error)
        }
    }
    
    func addDataProxyObserver(observer:DataProxyObserver) {
        observers.append(observer)
    }
    
    func removeDataProxyObserver(observer:DataProxyObserver) {
        if let index = observers.indexOf({return $0.isEqual(observer)}) {
            observers.removeAtIndex(index)
        }
    }
    
    func notifyUpdatedLists() {
        observers.map({$0.dataProxyUpdatedLists(self)})
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let listDicts = applicationContext["lists"] as? [[String:AnyObject]] {
            lists = []
            for listDict in listDicts {
                if let list = ListInfo(dictionary: listDict) {
                    lists.append(list)
                }
            }
            notifyUpdatedLists()
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        
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
    
    init?(dictionary:[String:AnyObject]) {
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
    
    override init?(dictionary:[String:AnyObject]) {
        var items:[ListItem]? = nil
        if let itemDicts = dictionary["items"] as? [[String: AnyObject]] {
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
