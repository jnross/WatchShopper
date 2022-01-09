//
//  WatchSync.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/10/21.
//

import Foundation
import WatchConnectivity
import UIKit

protocol WatchSyncDelegate {
    func watchSync(_ watchSync: WatchSync, updated list: Checklist)
    func watchSync(_ watchSync: WatchSync, updated lists: [Checklist])
    func watchSyncActivated(_ watchSync: WatchSync)
}

class WatchSync: NSObject {
    let session: WCSession
    var delegate: WatchSyncDelegate? = nil
    
    override init() {
        // Initialize variables before calling `super.init()`
        session = WCSession.default
        
        super.init()
        
        // Set things up after calling `super.init()`
        session.delegate = self
        
        NSLog("About to activate WCSession")
        session.activate()
    }
    
    func updateList(list: Checklist) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let json = try encoder.encode(list)
            let key = list.id.description
            var context = session.applicationContext
            context[key] = json
            NSLog("About to send message \(context) activated: \(session.activationState == .activated) reachable: \(session.isReachable)")
            session.sendMessage(context, replyHandler: {reply in
                NSLog("Got reply: \(reply)")
            }) { error in
                NSLog("Failed to send message: \(error)")
            }
        } catch {
            NSLog("Failed to serialize checklist with id: \(list.id), error: \(error)")
        }
    }
    
    func updateLists(lists: [Checklist]) {
        do {
            var context: [String : Any] = [:]
            try lists.forEach { list in
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let json = try encoder.encode(list)
                let key = list.id
                context[key] = json
            }
            if session.activationState != .activated {
                NSLog("WCSession is not activated!!")
            }
            NSLog("About to send message \(context) activated: \(session.activationState == .activated) reachable: \(session.isReachable)")
            session.sendMessage(context, replyHandler: { reply in
                NSLog("Got reply: \(reply)")
            }) { error in
                NSLog("Failed to send message: \(error)")
            }
        } catch {
            NSLog("Failed to serialize checklists, error: \(error)")
        }
    }
    
}

extension WatchSync: WCSessionDelegate {
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        NSLog("\(#function) \(#file):\(#line)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        NSLog("\(#function) \(#file):\(#line)")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        NSLog("\(#function) \(#file):\(#line) state: \(session.isPaired) \(session.isReachable) \(session.isWatchAppInstalled)")
    }
#endif
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("\(#function) \(#file):\(#line)")
        if activationState == .activated {
            NSLog("WCSession was activated! error: \(error)")
            delegate?.watchSyncActivated(self)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        NSLog("\(#function) \(#file):\(#line) reachability: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        var lists:[Checklist] = []
        
        for (key, value) in message {
            guard let data = value as? Data else {
                continue
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let checklist = try decoder.decode(Checklist.self, from: data)
                lists.append(checklist)
            } catch {
                NSLog("Failed to deserialize list at key \(key)")
            }
        }
        delegate?.watchSync(self, updated: lists)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler([:])
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        var lists:[Checklist] = []
        
        for (key, value) in applicationContext {
            guard let data = value as? Data else {
                continue
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let checklist = try decoder.decode(Checklist.self, from: data)
                lists.append(checklist)
            } catch {
                NSLog("Failed to deserialize list at key \(key)")
            }
        }
        delegate?.watchSync(self, updated: lists)
    }
}
