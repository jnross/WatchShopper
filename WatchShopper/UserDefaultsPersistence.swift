//
//  UserDefaultsPersistence.swift
//  WatchShopper
//
//  Created by Joseph Ross on 10/10/21.
//

import Foundation
import UIKit

class UserDefaultsPersistence {
    init() {
        
    }
    
    func saveEntity<E: Identifiable & Codable>(entity: E, tag: String) {
        let key = "\(tag)-\(entity.id)"
        let defaults = NSUbiquitousKeyValueStore.default
        do {
            let json = try JSONSerialization.data(withJSONObject: entity, options: .prettyPrinted)
            defaults.set(json, forKey: key)
        } catch {
            
        }
    }
}
