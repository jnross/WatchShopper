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
    func watchSync(_ watchSync: WatchSync, deleteListWithId id: String)
    func watchSyncSentRefresh(_ watchSync: WatchSync)
    func watchSyncActivated(_ watchSync: WatchSync)
}

enum WatchSyncMessage: Codable, CustomStringConvertible {
    case refresh
    case listUpdate(Checklist)
    case lists([Checklist])
    case updateLists([Checklist])
    case deleteList(String)

    var description: String {
        switch self {
        case .refresh:
            return "refresh"
        case .listUpdate:
            return "listUpdate"
        case .lists:
            return "lists"
        case .updateLists:
            return "updateLists"
        case .deleteList:
            return "deleteList"
        }
    }

    var verboseDescription: String {
        switch self {
        case .refresh:
            return "refresh"
        case .listUpdate(let list):
            return "listUpdate: \(list)"
        case .lists(let lists):
            return "lists: \(lists)"
        case .updateLists(let lists):
            return "updateLists: \(lists)"
        case .deleteList(let id):
            return "deleteList: \(id)"
        }
    }
    
}

class WatchSync: NSObject {
    let session: WCSession
    var delegate: WatchSyncDelegate? = nil
    let logger = Logger(tag: "WatchSync")
    
    override init() {
        // Initialize variables before calling `super.init()`
        session = WCSession.default
        
        super.init()
        
        // Set things up after calling `super.init()`
        session.delegate = self
        
        logger.log("About to activate WCSession")
        session.activate()
    }
    
    func updateList(list: Checklist) {
        sendMessage(.listUpdate(list))
    }
    
    func updateLists(lists: [Checklist]) {
        sendMessage(.lists(lists))
    }
    
    func sendRefresh() {
        sendMessage(.refresh)
    }
    
    private func sendMessage(_ message: WatchSyncMessage) {
#if os(iOS)
        logger.log("iOS: send message \(message)")
#else
        logger.log("watchOS: send message \(message)")
#endif
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let json = try encoder.encode(message)
            logger.log("About to send message \(json) activated: \(session.activationState == .activated) reachable: \(session.isReachable)")
            session.sendMessageData(json, replyHandler: {reply in
                self.logger.log("Got reply: \(reply)")
            }) { error in
                self.logger.log("Failed to send message: \(error)")
            }
        } catch {
            logger.log("Failed to serialize serialize and send message: \(message), error: \(error)")
        }
    }
    
}

extension WatchSync: WCSessionDelegate {
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.log("\(#function) \(#file):\(#line)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        logger.log("\(#function) \(#file):\(#line)")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        logger.log("\(#function) \(#file):\(#line) state: \(session.isPaired) \(session.isReachable) \(session.isWatchAppInstalled)")
    }
#endif
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.log("\(#function) \(#file):\(#line)")
        if activationState == .activated {
            logger.log("WCSession was activated! error: \(error ??? "nil")")
            delegate?.watchSyncActivated(self)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.log("\(#function) \(#file):\(#line) reachability: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let message = try decoder.decode(WatchSyncMessage.self, from: messageData)
            handleMessage(message)
            
        } catch {
            logger.log("Failed to deserialize message \(messageData)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(Data())
    }
    
    private func handleMessage(_ message: WatchSyncMessage) {
#if os(iOS)
        logger.log("iOS: rcv message \(message)")
#else
        logger.log("watchOS: rcv message \(message)")
#endif
        switch message {
        case .refresh:
            delegate?.watchSyncSentRefresh(self)
        case .listUpdate(let list):
            delegate?.watchSync(self, updated: list)
        case .lists(let lists):
            delegate?.watchSync(self, updated: lists)
        case .updateLists(let lists):
            delegate?.watchSync(self, updated: lists)
        case .deleteList(let listId):
            delegate?.watchSync(self, deleteListWithId: listId)
        }
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
                logger.log("Failed to deserialize list at key \(key)")
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
                logger.log("Failed to deserialize list at key \(key)")
            }
        }
        delegate?.watchSync(self, updated: lists)
    }
}
