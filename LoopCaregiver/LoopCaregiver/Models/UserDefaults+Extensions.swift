//
//  UserDefaults+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/12/23.
//

import Foundation

extension UserDefaults {
    
    private enum Key: String {
        case lastProfileExpirationAlertDate = "com.loopkit.Loop.lastProfileExpirationAlertDate"
    }
    
    public static let appGroup = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)
    
    public var lastProfileExpirationAlertDate: Date? {
        get {
            return object(forKey: Key.lastProfileExpirationAlertDate.rawValue) as? Date
        }
        set {
            set(newValue, forKey: Key.lastProfileExpirationAlertDate.rawValue)
        }
    }
}
