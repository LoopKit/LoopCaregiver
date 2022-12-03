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
    
    init(){
        self.glucoseDisplayUnits = UserDefaults.standard.glucosePreference.unit
        self.timelinePredictionEnabled = UserDefaults.standard.timelinePredictionEnabled
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
    
    @objc dynamic var glucosePreference: GlucoseUnitPrefererence {
        return GlucoseUnitPrefererence(rawValue: integer(forKey: glucoseUnitKey)) ?? .milligramsPerDeciliter
    }
    
    @objc dynamic var timelinePredictionEnabled: Bool {
        return UserDefaults.standard.bool(forKey: timelinePredictionEnabledKey)
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
