//
//  EvernoteSynchronizer.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/11/16.
//  Copyright © 2016 Easy Street 3. All rights reserved.
//

import UIKit

let kMaxNotes:Int32 = 32

@objc protocol EvernoteSynchronizerObserver: class {
    func synchronizer(_ synchronizer:EvernoteSynchronizer, updatedChecklists:[Checklist])
    func synchronizerFailedToUpdate(_ synchronizer:EvernoteSynchronizer)
}

struct ObserverWrapper {
    weak var observer:EvernoteSynchronizerObserver? = nil
}

enum Result<T> {
    case ok(T)
    case err(Error)
}

extension ENError {
    static var unknown: NSError {
        return NSError(domain: ENErrorDomain, code: Int(EDAMErrorCode_UNKNOWN.rawValue), userInfo: nil)
    }
}

class EvernoteSynchronizer: NSObject {
    @objc static let shared = EvernoteSynchronizer()
    private var observerWrappers:[ObserverWrapper] = []
    @objc var allNotebookNames:[String] = []
    var gatheringNotebooks:Set<EDAMNotebook> = []
    var gatheringChecklists:[Checklist] = []
    
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
    
    func notifyFailure() {
        for observerWrapper in self.observerWrappers {
            observerWrapper.observer?.synchronizerFailedToUpdate(self)
        }
    }
    
    @objc func refreshWatchNotes() {
        getAllNotebooks() { result in
            guard case let .ok(notebooks) = result else {
                //TODO: report error to user
                self.notifyFailure()
                return
            }
            self.gatheringNotebooks = Set(notebooks)
            notebooks.forEach { notebook in
                self.getWatchNotesFor(notebook: notebook) { result in
                    guard case let .ok(notes) = result else {
                        // TODO: handle single notebook failure?
                        self.finish(notebook)
                        return
                    }
                    self.gatheringChecklists += notes.map { Checklist(note: $0) }
                    self.finish(notebook)
                }
            }
        }
    }
    
    func finish(_ notebook: EDAMNotebook) {
        gatheringNotebooks.remove(notebook)
        if gatheringNotebooks.isEmpty {
            for observerWrapper in self.observerWrappers {
                observerWrapper.observer?.synchronizer(self, updatedChecklists: gatheringChecklists)
            }
            gatheringChecklists = []
        }
    }
    
    func getAllNotebooks(completion: @escaping (Result<[EDAMNotebook]>) -> Void) {
        ENSession.shared.primaryNoteStore()?.listNotebooks { (notebooksOpt, error) in
            if let error = error {
                completion(.err(error))
                return
            }
            guard let notebooks = notebooksOpt else { return }
            self.allNotebookNames = notebooks.map(){ return $0.name }
            completion(.ok(notebooks))
        }
    }
    
    func getWatchNotesFor(notebook:EDAMNotebook, completion:@escaping (Result<[EDAMNote]>) -> Void) {
        let targetNotebookNames = ESSettingsManager.shared().targetNotebookNames()
        if targetNotebookNames?.contains(notebook.name) ?? false {
            getAllNotesFor(notebook:notebook, completion: completion)
        } else {
            getTaggedNotesFor(notebook:notebook, completion: completion)
        }
    }
    
    func getTaggedNotesFor(notebook:EDAMNotebook, completion:@escaping (Result<[EDAMNote]>) -> Void) {
        self.getTagsFor(notebook: notebook) { result in
            guard case let .ok(tags) = result else {
                switch result {
                case let .err(error):
                    completion(.err(error))
                default:
                    completion(.err(ENError.unknown))
                }
                return
            }
            let guids = tags.map() { tag in return tag.guid! }
            let filter = EDAMNoteFilter()
            filter.order = NSNumber(value: NoteSortOrder_UPDATED.rawValue)
            filter.ascending = false
            filter.notebookGuid = notebook.guid
            filter.inactive = false
            filter.tagGuids = guids
            ENSession.shared.primaryNoteStore()?.findNotes(with: filter, offset: 0, maxNotes: kMaxNotes) { noteList, error in
                if let error = error {
                    completion(.err(error))
                    return
                }
                completion(.ok(noteList?.notes ?? []))
            }
        }
    }
    
    func getTagsFor(notebook: EDAMNotebook, completion: @escaping (Result<[EDAMTag]>) -> Void) {
        ENSession.shared.primaryNoteStore()?.listTagsInNotebook(withGuid: notebook.guid) { tagsOpt, error in
            if let error = error {
                completion(.err(error))
                return
            }
            guard let tags = tagsOpt else {
                completion(.ok([]))
                return
            }
            let targetTags = ESSettingsManager.shared().targetTags()
            let filteredTags = tags.filter() { tag in
                return targetTags?.contains(tag.name) ?? false
            }
            completion(.ok(filteredTags))
        }
    }
    
    func getAllNotesFor(notebook: EDAMNotebook, completion: @escaping (Result<[EDAMNote]>) -> Void) {
        let filter = EDAMNoteFilter()
        filter.order = NSNumber(value:NoteSortOrder_UPDATED.rawValue)
        filter.ascending = false
        filter.notebookGuid = notebook.guid
        filter.inactive = false
        ENSession.shared.primaryNoteStore()?.findNotes(with: filter, offset: 0, maxNotes: kMaxNotes) { noteList, error in
            if let error = error {
                completion(.err(error))
                return
            }
            completion(.ok(noteList?.notes ?? []))
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
