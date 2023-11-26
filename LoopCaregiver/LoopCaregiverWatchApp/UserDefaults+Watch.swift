//
//  UserDefaults+Watch.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/23.
//

import Foundation

extension UserDefaults {
    @objc public dynamic var lastPhoneDebugMessage: String? {
        guard let message = object(forKey: "lastPhoneDebugMessage") as? String else {
            return nil
        }

        return message
    }
    
    @objc public func updateLastPhoneDebugMessage(_ message: String) {
        setValue(message, forKey: "lastPhoneDebugMessage")
    }
}
