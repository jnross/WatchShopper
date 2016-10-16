//
//  EvernoteSynchronizer.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/11/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import UIKit
import RxSwift

let kMaxNotes:Int32 = 32

@objc protocol EvernoteSynchronizerObserver: class {
    func synchronizer(_ synchronizer:EvernoteSynchronizer, updatedChecklists:[ESChecklist])
}

struct ObserverWrapper {
    weak var observer:EvernoteSynchronizerObserver? = nil
}

class EvernoteSynchronizer: NSObject {
    static let shared = EvernoteSynchronizer()
    private var observerWrappers:[ObserverWrapper] = []
    var disposeBag = DisposeBag()
    
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
                self.refreshWatchNotes()
            }
        }
    }
    
    func logout() {
        ENSession.shared().unauthenticate()
    }
    
    func isAlreadyAuthenticated() -> Bool {
        return ENSession.shared().isAuthenticated
    }
    
    func refreshWatchNotes() {
        disposeBag = DisposeBag()
        getAllNotebooks()
            .map({ notebook in
                return self.getWatchNotesFor(notebook: notebook)
            })
            .merge()
            .reduce([EDAMNote]()) { (accumulator, notes) in
                return accumulator + notes
            }
            .map({ (notes:[EDAMNote]) -> [ESChecklist] in
                var checklists:[ESChecklist] = []
                for note in notes {
                    checklists.append(ESChecklist(note: note))
                }
                return checklists
            })
            .subscribe(onNext: { (checklists) in
                for observerWrapper in self.observerWrappers {
                    observerWrapper.observer?.synchronizer(self, updatedChecklists: checklists)
                }
            })
            .addDisposableTo(disposeBag)
        
    }
    
    func getAllNotebooks() -> Observable<EDAMNotebook> {
        return Observable.create() { observer in
            ENSession.shared().primaryNoteStore().listNotebooks(success: { (notebooksOpt) in
                guard let notebooks = notebooksOpt as? [EDAMNotebook] else { return }
                for notebook in notebooks {
                    observer.on(.next(notebook))
                }
                observer.on(.completed)
                }, failure: { error in
                    observer.on(.error(error!))
            })
            return Disposables.create()
        }
    }
    
    func getWatchNotesFor(notebook:EDAMNotebook) -> Observable<[EDAMNote]> {
        let targetNotebookNames = ESSettingsManager.shared().targetNotebookNames()
        if targetNotebookNames?.contains(notebook.name) ?? false {
            return getTaggedNotesFor(notebook:notebook)
        } else {
            return getAllNotesFor(notebook:notebook)
        }
    }
    
    func getTaggedNotesFor(notebook:EDAMNotebook) ->Observable<[EDAMNote]> {
        return Observable.create() { observer in
            observer.on(.completed)
            return Disposables.create()
        }
    }
    
    func getAllNotesFor(notebook:EDAMNotebook) -> Observable<[EDAMNote]> {
        return Observable.create() { observer in
            let filter = EDAMNoteFilter()
            filter.order = 2
            filter.ascending = false
            filter.notebookGuid = notebook.guid
            filter.inactive = false
            ENSession.shared().primaryNoteStore().findNotes(with: filter, offset: 0, maxNotes: kMaxNotes, success: { noteList in
                if let notes = noteList?.notes as? [EDAMNote] {
                    observer.on(.next(notes))
                }
                observer.on(.completed)
                }, failure: { error in
                    observer.on(.error(error!))
                    
            })
            return Disposables.create()
        }
    }
}
