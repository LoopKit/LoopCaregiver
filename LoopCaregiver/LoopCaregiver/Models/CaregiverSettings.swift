//
//  CaregiverSettings.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/25/22.
//

import Foundation
import HealthKit

class CaregiverSettings: ObservableObject {
    
    @Published var glucoseDisplayUnits: HKUnit
    @Published var timelinePredictionEnabled: Bool
    @Published var experimentalFeaturesUnlocked: Bool
    @Published var remoteCommands2Enabled: Bool
    @Published var disclaimerAcceptedDate: Date?
    
    init(){
        Self.migrateUserDefaultsToAppGroup()
        self.glucoseDisplayUnits = UserDefaults.appGroupDefaults.glucosePreference.unit
        self.timelinePredictionEnabled = UserDefaults.appGroupDefaults.timelinePredictionEnabled
        self.remoteCommands2Enabled = UserDefaults.appGroupDefaults.remoteCommands2Enabled
        self.experimentalFeaturesUnlocked = UserDefaults.appGroupDefaults.experimentalFeaturesUnlocked
        self.disclaimerAcceptedDate = UserDefaults.appGroupDefaults.disclaimerAcceptedDate
        
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func defaultsChanged(notication: Notification){
        let glucoseDisplayUnits = UserDefaults.appGroupDefaults.glucosePreference.unit
        if self.glucoseDisplayUnits != glucoseDisplayUnits {
            self.glucoseDisplayUnits = glucoseDisplayUnits
        }
        
        if self.timelinePredictionEnabled != UserDefaults.appGroupDefaults.timelinePredictionEnabled {
            self.timelinePredictionEnabled = UserDefaults.appGroupDefaults.timelinePredictionEnabled
        }
        
        if self.remoteCommands2Enabled != UserDefaults.appGroupDefaults.remoteCommands2Enabled {
            self.remoteCommands2Enabled = UserDefaults.appGroupDefaults.remoteCommands2Enabled
        }
        
        if self.experimentalFeaturesUnlocked != UserDefaults.appGroupDefaults.experimentalFeaturesUnlocked {
            self.experimentalFeaturesUnlocked = UserDefaults.appGroupDefaults.experimentalFeaturesUnlocked
        }
        
        if self.disclaimerAcceptedDate != UserDefaults.appGroupDefaults.disclaimerAcceptedDate {
            self.disclaimerAcceptedDate = UserDefaults.appGroupDefaults.disclaimerAcceptedDate
        }
    }
    
    func formatGlucoseQuantity(_ quantity: HKQuantity) -> Double {
        return quantity.doubleValue(for: glucoseDisplayUnits)
    }
    
    func presentableGlucoseQuantity(_ quantity: HKQuantity) -> String {
        let unitInUserUnits = quantity.doubleValue(for: glucoseDisplayUnits)
        if glucoseDisplayUnits == .milligramsPerDeciliter {
            return String(format: "%.0f", unitInUserUnits)
        } else if glucoseDisplayUnits == .millimolesPerLiter {
            return String(format: "%.1f", unitInUserUnits)
        } else {
            return "Error: Unknown units"
        }
    }
    
    func presentableGlucoseQuantityWithUnits(_ quantity: HKQuantity) -> String {
        if glucoseDisplayUnits == .milligramsPerDeciliter {
            return "\(presentableGlucoseQuantity(quantity)) mg/dL"
        } else if glucoseDisplayUnits == .millimolesPerLiter {
            return "\(presentableGlucoseQuantity(quantity)) mmol/L"
        } else {
            return "Error: Missing units"
        }
    }
    
    static func migrateUserDefaultsToAppGroup() {
    
        let defaultUserDefaults = UserDefaults.standard
        let groupDefaults = UserDefaults.appGroupDefaults
        let didMigrateToAppGroups = "DidMigrateToAppGroups"
        
        guard !groupDefaults.bool(forKey: didMigrateToAppGroups) else {
            return
        }
        
        for key in defaultUserDefaults.dictionaryRepresentation().keys {
            groupDefaults.set(defaultUserDefaults.dictionaryRepresentation()[key], forKey: key)
        }
        
        groupDefaults.set(true, forKey: didMigrateToAppGroups)
        groupDefaults.synchronize()
        print("Successfully migrated defaults")
    }
}


extension UserDefaults {
    
    static var appGroupDefaults: UserDefaults {
        UserDefaults(suiteName: Bundle.main.appGroupSuiteName)!
    }
    
    var glucoseUnitKey: String {
        return "glucoseUnit"
    }
    
    var timelinePredictionEnabledKey: String {
        return "timelinePredictionEnabled"
    }
    
    var remoteCommands2EnabledKey: String {
        return "remoteCommands2Enabled"
    }
    
    var experimentalFeaturesUnlockedKey: String {
        return "experimentalFeaturesUnlocked"
    }
    
    var disclaimerAcceptedDateKey: String {
        return "disclaimerAcceptedDate"
    }
    
    @objc dynamic var glucosePreference: GlucoseUnitPrefererence {
        return GlucoseUnitPrefererence(rawValue: integer(forKey: glucoseUnitKey)) ?? .milligramsPerDeciliter
    }
    
    @objc dynamic var timelinePredictionEnabled: Bool {
        return UserDefaults.appGroupDefaults.bool(forKey: timelinePredictionEnabledKey)
    }
    
    @objc dynamic var remoteCommands2Enabled: Bool {
        return UserDefaults.appGroupDefaults.bool(forKey: remoteCommands2EnabledKey)
    }
    
    @objc dynamic var experimentalFeaturesUnlocked: Bool {
        return UserDefaults.appGroupDefaults.bool(forKey: experimentalFeaturesUnlockedKey)
    }
    
    @objc dynamic var disclaimerAcceptedDate: Date? {
        guard let rawString = UserDefaults.appGroupDefaults.string(forKey: disclaimerAcceptedDateKey) else {
            return nil
        }
        return Date(rawValue: rawString)
    }
}

@objc enum GlucoseUnitPrefererence: Int, Codable, CaseIterable {
    case milligramsPerDeciliter
    case millimolesPerLiter
    
    var presentableDescription: String {
        switch self {
        case .milligramsPerDeciliter:
            return "mg/dL"
        case .millimolesPerLiter:
            return "mmol/L"
        }
    }
    
    var unit: HKUnit {
        switch self {
        case .milligramsPerDeciliter:
            return .milligramsPerDeciliter
        case .millimolesPerLiter:
            return .millimolesPerLiter
        }
    }
}
