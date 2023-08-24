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
        self.glucoseDisplayUnits = UserDefaults.standard.glucosePreference.unit
        self.timelinePredictionEnabled = UserDefaults.standard.timelinePredictionEnabled
        self.remoteCommands2Enabled = UserDefaults.standard.remoteCommands2Enabled
        self.experimentalFeaturesUnlocked = UserDefaults.standard.experimentalFeaturesUnlocked
        self.disclaimerAcceptedDate = UserDefaults.standard.disclaimerAcceptedDate
        
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func defaultsChanged(notication: Notification){
        let glucoseDisplayUnits = UserDefaults.standard.glucosePreference.unit
        if self.glucoseDisplayUnits != glucoseDisplayUnits {
            self.glucoseDisplayUnits = glucoseDisplayUnits
        }
        
        if self.timelinePredictionEnabled != UserDefaults.standard.timelinePredictionEnabled {
            self.timelinePredictionEnabled = UserDefaults.standard.timelinePredictionEnabled
        }
        
        if self.remoteCommands2Enabled != UserDefaults.standard.remoteCommands2Enabled {
            self.remoteCommands2Enabled = UserDefaults.standard.remoteCommands2Enabled
        }
        
        if self.experimentalFeaturesUnlocked != UserDefaults.standard.experimentalFeaturesUnlocked {
            self.experimentalFeaturesUnlocked = UserDefaults.standard.experimentalFeaturesUnlocked
        }
        
        if self.disclaimerAcceptedDate != UserDefaults.standard.disclaimerAcceptedDate {
            self.disclaimerAcceptedDate = UserDefaults.standard.disclaimerAcceptedDate
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
}


extension UserDefaults {
    
    var glucoseUnitKey: String {
        return "glucoseUnit"
    }
    
    var timelinePredictionEnabledKey: String {
        return "timelinePredictionEnabled"
    }
    
    var timelineVisibleLookbackHoursKey: String {
        return "timelineVisibleLookbackHours"
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
        return UserDefaults.standard.bool(forKey: timelinePredictionEnabledKey)
    }
    
    @objc dynamic var remoteCommands2Enabled: Bool {
        return UserDefaults.standard.bool(forKey: remoteCommands2EnabledKey)
    }
    
    @objc dynamic var experimentalFeaturesUnlocked: Bool {
        return UserDefaults.standard.bool(forKey: experimentalFeaturesUnlockedKey)
    }
    
    @objc dynamic var disclaimerAcceptedDate: Date? {
        guard let rawString = UserDefaults.standard.string(forKey: disclaimerAcceptedDateKey) else {
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
