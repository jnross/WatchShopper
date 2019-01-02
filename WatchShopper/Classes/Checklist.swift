//
//  Checklist.swift
//  WatchShopper
//
//  Created by Joseph Ross on 12/31/18.
//  Copyright © 2018 Easy Street 3. All rights reserved.
//

import Foundation

protocol ChecklistObserver: class {
    func checklistDidRefresh(_: Checklist)
    func checklist(_: Checklist, updatedItem: ChecklistItem)
}

class Checklist: NSObject {
    var name: String
    var guid: String
    var note: EDAMNote? = nil
    var lastUpdated: Date
    weak var observer: ChecklistObserver? = nil
    var items:[ChecklistItem] = []
    
    fileprivate var elementStack: [String] = []
    fileprivate var currentItemId: UInt8 = 0
    fileprivate var accumulatedText: String = ""
    
    init(name: String, guid: String) {
        self.name = name
        self.guid = guid
        self.lastUpdated = Date()
    }
    
    convenience init(note: EDAMNote) {
        self.init(name: note.title, guid: note.guid)
        self.lastUpdated = NSDate(edamTimestamp: note.updated.int64Value) as Date
        self.note = note
        if note.content != nil {
            self.loadContent()
        }
    }
    
    func loadContent() {
        guard let data = note?.content.data(using: .utf8) else {
            // TODO: log unexpected missing content
            return
        }
        let parser = XMLParser(data: data)
        parser.delegate = self
        elementStack = []
        currentItemId = 0
        parser.parse()
        elementStack = []
        accumulatedText = ""
    }
    
    func saveToEvernote() {
        var content = "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note><div>"
        for item in items {
            content.append("<div><en-todo\(item.checked ? "checked=\"true\"": "")></en-todo>\(item.name)</div>")
        }
        content.append("</div></en-note>")
        self.note?.content = content;
        EvernoteSynchronizer.shared.save(checklist: self)
    }
    
    var prettyDateString: String? {
        
        let interval = self.lastUpdated.timeIntervalSinceNow
        let twoDaysAgo: TimeInterval = -60 * 60 * 24 * 2
        
        if interval < twoDaysAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM dd, yyyy"
            return formatter.string(from: lastUpdated)
        } else {
            let formatter = TTTTimeIntervalFormatter()
            return formatter.string(for: interval)
        }
    }
}

extension Checklist: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let trimmedText = accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if elementStack.count < 2, trimmedText.count > 0 {
            let item = ChecklistItem(name: trimmedText, id: currentItemId, checked: false)
            currentItemId += 1
            items.append(item)
            accumulatedText = ""
        }
        var stackItem = elementName
        if doesElement(elementName, flagItemAsCheckedWithAttributes:attributeDict) {
            stackItem = "checked"
        }
        elementStack.append(stackItem)
    }
    
    func doesElement(_ elementName: String, flagItemAsCheckedWithAttributes attributeDict: [String: String]) -> Bool {
        let isSpan = elementName == "span"
        let style = attributeDict["style"]
        let hasLineThrough = style?.contains("line-through") ?? false
        
        if isSpan, hasLineThrough {
            return true
        }
        
        let isTodo = elementName == "en-todo"
        let checkedString = attributeDict["checked"]
        let checked = checkedString == "true"
        if isTodo, checked {
            return true
        }
        return false
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedText = accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.count > 0 {
            let checked = elementStack.contains("checked")
            let item = ChecklistItem(name:trimmedText, id: currentItemId, checked: checked)
            currentItemId += 1
            items.append(item)
            accumulatedText = ""
        } else if elementStack.last == "checked" {
            elementStack.removeLast()
            elementStack.removeLast()
            elementStack.append("checked")
            elementStack.append("checked")
        }
        elementStack.removeLast()
    }
    
    func parser(_ parser: XMLParser, foundCharacters: String) {
        accumulatedText.append(foundCharacters)
    }
}
