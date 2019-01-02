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
    func synchronizer(_ synchronizer:EvernoteSynchronizer, updatedChecklists:[Checklist])
}

struct ObserverWrapper {
    weak var observer:EvernoteSynchronizerObserver? = nil
}

class EvernoteSynchronizer: NSObject {
    @objc static let shared = EvernoteSynchronizer()
    private var observerWrappers:[ObserverWrapper] = []
    @objc var allNotebookNames:[String] = []
    var disposeBag = DisposeBag()
    
    override init() {
        let consumerKey = "jnross"
        let consumerSecret = "[REDACTED]"
        ENSession.setSharedSessionConsumerKey(consumerKey,
                                              consumerSecret: consumerSecret,
                                              optionalHost: nil)
//                                              optionalHost: ENSessionHostSandbox)
    }
    
    @objc func addObserver(_ observer:EvernoteSynchronizerObserver) {
        observerWrappers.append(ObserverWrapper(observer: observer))
    }
    
    @objc func removeObserver(_ observer:EvernoteSynchronizerObserver) {
        observerWrappers = observerWrappers.filter() { wrapper in
            if let wrapped = wrapper.observer, wrapped !== observer {
                return true
            }
            return false
        }
    }
    
    @objc func authenticateEvernoteUserWith(viewController:UIViewController) {
        let session = ENSession.shared
        session.authenticate(with: viewController, preferRegistration: false) { error in
            if error != nil || !session.isAuthenticated {
                let alert = UIAlertController(title: nil, message:"Evernote authentication failed", preferredStyle: .alert)
                alert.show(viewController, sender: self)
            } else {
                self.refreshWatchNotes()
            }
        }
    }
    
    @objc func logout() {
        ENSession.shared.unauthenticate()
    }
    
    @objc func isAlreadyAuthenticated() -> Bool {
        return ENSession.shared.isAuthenticated
    }
    
    @objc func refreshWatchNotes() {
        disposeBag = DisposeBag()
        getAllNotebooks()
            .map({ notebook in
                return self.getWatchNotesFor(notebook: notebook)
            })
            .merge()
            .reduce([EDAMNote]()) { (accumulator, notes) in
                return accumulator + notes
            }
            .map({ (notes:[EDAMNote]) -> [Checklist] in
                var checklists:[Checklist] = []
                for note in notes {
                    checklists.append(Checklist(note: note))
                }
                return checklists.sorted(by: { first, second in
                    return first.lastUpdated > second.lastUpdated
                })
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
            ENSession.shared.primaryNoteStore()?.listNotebooks(completion: { (notebooksOpt, error) in
                if let error = error {
                    observer.on(.error(error))
                    return
                }
                guard let notebooks = notebooksOpt else { return }
                self.allNotebookNames = notebooks.map(){ return $0.name }
                for notebook in notebooks {
                    observer.on(.next(notebook))
                }
                observer.on(.completed)
            })
            return Disposables.create()
        }
    }
    
    func getWatchNotesFor(notebook:EDAMNotebook) -> Observable<[EDAMNote]> {
        let targetNotebookNames = ESSettingsManager.shared().targetNotebookNames()
        if targetNotebookNames?.contains(notebook.name) ?? false {
            return getAllNotesFor(notebook:notebook)
        } else {
            return getTaggedNotesFor(notebook:notebook)
        }
    }
    
    func getTaggedNotesFor(notebook:EDAMNotebook) ->Observable<[EDAMNote]> {
        return Observable.create() { observer in
            var fetchTasks = 0
            self.getTagsFor(notebook: notebook).subscribe(onNext:
                { tags in
                    fetchTasks += 1
                    let guids = tags.map() { tag in return tag.guid! }
                    let filter = EDAMNoteFilter()
                    filter.order = NSNumber(value: NoteSortOrder_UPDATED.rawValue)
                    filter.ascending = false
                    filter.notebookGuid = notebook.guid
                    filter.inactive = false
                    filter.tagGuids = guids
                    ENSession.shared.primaryNoteStore()?.findNotes(with: filter, offset: 0, maxNotes: kMaxNotes, completion: { noteList, error in
                        if let error = error {
                            observer.on(.error(error))
                            return
                        }
                        if let notes = noteList?.notes {
                            observer.on(.next(notes))
                        }
                        fetchTasks -= 1
                        if fetchTasks == 0 { observer.on(.completed) }
                    })
                },onCompleted:{
                    if fetchTasks == 0 { observer.on(.completed) }
            }).addDisposableTo(self.disposeBag)
            return Disposables.create()
        }
    }
    
    func getTagsFor(notebook:EDAMNotebook) -> Observable<[EDAMTag]> {
        return Observable.create { observer in
            ENSession.shared.primaryNoteStore()?.listTagsInNotebook(withGuid: notebook.guid, completion:
                { tagsOpt, error in
                    if let error = error {
                        observer.on(.error(error))
                        return
                    }
                    guard let tags = tagsOpt else {
                        observer.on(.completed)
                        return
                    }
                    let targetTags = ESSettingsManager.shared().targetTags()
                    let filteredTags = tags.filter() { tag in
                        return targetTags?.contains(tag.name) ?? false
                    }
                    if filteredTags.count > 0 {
                        observer.on(.next(filteredTags))
                    }
                    observer.on(.completed)
                })
            return Disposables.create()
        }
    }
    
    func getAllNotesFor(notebook:EDAMNotebook) -> Observable<[EDAMNote]> {
        return Observable.create() { observer in
            let filter = EDAMNoteFilter()
            filter.order = NSNumber(value:NoteSortOrder_UPDATED.rawValue)
            filter.ascending = false
            filter.notebookGuid = notebook.guid
            filter.inactive = false
            ENSession.shared.primaryNoteStore()?.findNotes(with: filter, offset: 0, maxNotes: kMaxNotes, completion: { noteList, error in
                if let error = error {
                    observer.on(.error(error))
                    return
                }
                if let notes = noteList?.notes {
                    observer.on(.next(notes))
                }
                observer.on(.completed)
            })
            return Disposables.create()
        }
    }
    
    @objc func loadContent(for checklist:Checklist, success:@escaping ()->Void, failure:@escaping (Error)->Void) {
        guard let guid = checklist.note?.guid else { return }
        ENSession.shared.primaryNoteStore()?.fetchNoteContent(withGuid: guid, completion:
            { content, error in
                if let error = error {
                    failure(error)
                    return
                }
                checklist.note?.content = content
                checklist.loadContent()
                success()
            })
    }
    
    func save(checklist:Checklist) {
        guard let note = checklist.note else { return }
        ENSession.shared.primaryNoteStore()?.update(note, completion: { note, error in
                //TODO: notify user of failure
        })
    }
}
