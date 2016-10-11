//
//  EvernoteSynchronizer.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/11/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import UIKit

@objc protocol EvernoteSynchronizerObserver: class {
    func synchronizerUpdatedChecklists(synchronizer:ESEvernoteSynchronizer)
}

struct ObserverWrapper {
    weak var observer:EvernoteSynchronizerObserver? = nil
}

class EvernoteSynchronizer: NSObject {
    static let sharedSynchronizer = EvernoteSynchronizer()
    private var observerWrappers:[ObserverWrapper] = []
    
    override init() {
        let consumerKey = "jnross"
        let consumerSecret = "[REDACTED]"
        ENSession.setSharedSessionConsumerKey(consumerKey,
                                              consumerSecret: consumerSecret,
                                              optionalHost: nil)
//                                              optionalHost: ENSessionHostSandbox)
    }
    
    func addObserver(_ observer:EvernoteSynchronizerObserver) {
        observerWrappers.append(ObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer:EvernoteSynchronizerObserver) {
        observerWrappers = observerWrappers.filter() { wrapper in
            if let wrapped = wrapper.observer, wrapped !== observer {
                return true
            }
            return false
        }
    }
    
    func authenticateEvernoteUserWith(viewController:UIViewController) {
        guard let session = ENSession.shared() else { return }
        session.authenticate(with: viewController, preferRegistration: false) { error in
            if error != nil || !session.isAuthenticated {
                let alert = UIAlertController(title: nil, message:"Evernote authentication failed", preferredStyle: .alert)
                alert.show(viewController, sender: self)
            } else {
                self.getWatchNotes()
            }
        }
    }
    
    func logout() {
        ENSession.shared().unauthenticate()
    }
    
    var isAlreadyAuthenticated:Bool {
        get {
            return ENSession.shared().isAuthenticated
        }
    }
    
    func getWatchNotes() {
        
    }
}
