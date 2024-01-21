//
//  CaregiverSettings.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/25/22.
//

import Combine
import Foundation
import HealthKit

public class CaregiverSettings: ObservableObject {
    
    @Published public var glucoseDisplayUnits: HKUnit
    @Published public var timelinePredictionEnabled: Bool
    @Published public var experimentalFeaturesUnlocked: Bool
    @Published public var remoteCommands2Enabled: Bool
    @Published public var demoModeEnabled: Bool
    @Published public var disclaimerAcceptedDate: Date?
    @Published public var maxCarbAmount: Int
    @Published public var maxBolusAmount: Int
    
    let userDefaults: UserDefaults
    
    var cancellables = [AnyCancellable]()
    
    public let appGroupsSupported: Bool
    
    public init(userDefaults: UserDefaults, appGroupsSupported: Bool){
        
        self.userDefaults = userDefaults
        self.appGroupsSupported = appGroupsSupported
        
        //Migrations
        if appGroupsSupported {
            Self.migrateUserDefaultsToAppGroup(userDefaults: userDefaults)
        }

        //Defaults
        self.glucoseDisplayUnits = userDefaults.glucosePreference.unit
        self.timelinePredictionEnabled = userDefaults.timelinePredictionEnabled
        self.remoteCommands2Enabled = userDefaults.remoteCommands2Enabled
        self.demoModeEnabled = userDefaults.demoModeEnabled
        self.experimentalFeaturesUnlocked = userDefaults.experimentalFeaturesUnlocked
        self.disclaimerAcceptedDate = userDefaults.disclaimerAcceptedDate
        self.maxCarbAmount = userDefaults.maxCarbAmount
        self.maxBolusAmount = userDefaults.maxBolusAmount
        
        //Binding
        self.bindToPublishers()
        self.bindToUserDefaults()
    }
    
    func bindToPublishers() {
        $glucoseDisplayUnits.sink { val in
            if val != self.userDefaults.glucosePreference.unit {
                self.userDefaults.set(val, forKey: self.userDefaults.glucoseUnitKey)
            }
        }.store(in: &cancellables)
        
        $timelinePredictionEnabled.sink { val in
            if val != self.userDefaults.timelinePredictionEnabled {
                self.userDefaults.setValue(val, forKey: self.userDefaults.timelinePredictionEnabledKey)
            }
        }.store(in: &cancellables)
        
        $remoteCommands2Enabled.sink { val in
            if val != self.userDefaults.remoteCommands2Enabled {
                self.userDefaults.setValue(val, forKey: self.userDefaults.remoteCommands2EnabledKey)
            }
        }.store(in: &cancellables)
        
        $demoModeEnabled.sink { val in
            if val != self.userDefaults.demoModeEnabled {
                self.userDefaults.setValue(val, forKey: self.userDefaults.demoModeEnabledKey)
            }
        }.store(in: &cancellables)
        
        $experimentalFeaturesUnlocked.sink { val in
            if val != self.userDefaults.experimentalFeaturesUnlocked {
                self.userDefaults.setValue(val, forKey: self.userDefaults.experimentalFeaturesUnlockedKey)
            }
        }.store(in: &cancellables)
        
        $disclaimerAcceptedDate.sink { val in
            if val != self.userDefaults.disclaimerAcceptedDate {
                self.userDefaults.setValue(val, forKey: self.userDefaults.disclaimerAcceptedDateKey)
            }
        }.store(in: &cancellables)
        
        $maxCarbAmount.sink { val in
            if val != self.userDefaults.maxCarbAmount {
                self.userDefaults.setValue(val, forKey: self.userDefaults.maxCarbAmountKey)
            }
        }.store(in: &cancellables)
        
        $maxBolusAmount.sink { val in
            if val != self.userDefaults.maxBolusAmount {
                self.userDefaults.setValue(val, forKey: self.userDefaults.maxBolusAmountKey)
            }
        }.store(in: &cancellables)
    }
    
    func bindToUserDefaults() {
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func defaultsChanged(notication: Notification){

        let glucoseDisplayUnits = userDefaults.glucosePreference.unit
        if self.glucoseDisplayUnits != glucoseDisplayUnits {
            self.glucoseDisplayUnits = glucoseDisplayUnits
        }
        
        if self.timelinePredictionEnabled != userDefaults.timelinePredictionEnabled {
            self.timelinePredictionEnabled = userDefaults.timelinePredictionEnabled
        }
        
        if self.remoteCommands2Enabled != userDefaults.remoteCommands2Enabled {
            self.remoteCommands2Enabled = userDefaults.remoteCommands2Enabled
        }
        
        if self.demoModeEnabled != userDefaults.demoModeEnabled {
            self.demoModeEnabled = userDefaults.demoModeEnabled
        }
        
        if self.experimentalFeaturesUnlocked != userDefaults.experimentalFeaturesUnlocked {
            self.experimentalFeaturesUnlocked = userDefaults.experimentalFeaturesUnlocked
        }
        
        if self.disclaimerAcceptedDate != userDefaults.disclaimerAcceptedDate {
            self.disclaimerAcceptedDate = userDefaults.disclaimerAcceptedDate
        }
        
        if self.maxCarbAmount != userDefaults.maxCarbAmount {
            self.maxCarbAmount = userDefaults.maxCarbAmount
        }
        
        if self.maxBolusAmount != userDefaults.maxBolusAmount {
            self.maxBolusAmount = userDefaults.maxBolusAmount
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
    
    //TODO: We should get rid of glucoseDisplayUnits and instead just use this.
    public func saveGlucoseUnitPreference(_ preference: GlucoseUnitPrefererence) {
        userDefaults.setValue(preference.rawValue, forKey: userDefaults.glucoseUnitKey)
    }
    
    public var glucoseUnitPreference: GlucoseUnitPrefererence {
        return userDefaults.glucosePreference
    }
    
    static func migrateUserDefaultsToAppGroup(userDefaults: UserDefaults) {
    
        let defaultUserDefaults = UserDefaults.standard
        let didMigrateToAppGroups = "DidMigrateToAppGroups"
        
        guard !userDefaults.bool(forKey: didMigrateToAppGroups) else {
            return
        }
        
        for key in defaultUserDefaults.dictionaryRepresentation().keys {
            userDefaults.set(defaultUserDefaults.dictionaryRepresentation()[key], forKey: key)
        }
        
        userDefaults.set(true, forKey: didMigrateToAppGroups)
        userDefaults.synchronize()
        print("Successfully migrated defaults")
    }
}


public extension UserDefaults {
    
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
    
    var demoModeEnabledKey: String {
        return "demoModeEnabled"
    }
    
    var experimentalFeaturesUnlockedKey: String {
        return "experimentalFeaturesUnlocked"
    }
    
    var disclaimerAcceptedDateKey: String {
        return "disclaimerAcceptedDate"
    }
    
    var maxCarbAmountKey: String {
        return "maxCarbsAmount"
    }
    
    var maxBolusAmountKey: String {
        return "maxBolusAmount"
    }
    
    @objc dynamic var glucosePreference: GlucoseUnitPrefererence {
        return GlucoseUnitPrefererence(rawValue: integer(forKey: glucoseUnitKey)) ?? .milligramsPerDeciliter
    }
    
    @objc dynamic var timelinePredictionEnabled: Bool {
        return bool(forKey: timelinePredictionEnabledKey)
    }
    
    @objc dynamic var remoteCommands2Enabled: Bool {
        return bool(forKey: remoteCommands2EnabledKey)
    }
    
    @objc dynamic var demoModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: demoModeEnabledKey)
    }
    
    @objc dynamic var experimentalFeaturesUnlocked: Bool {
        return bool(forKey: experimentalFeaturesUnlockedKey)
    }
    
    @objc dynamic var maxCarbAmount: Int {
        guard let maxCarbAmount = object(forKey: maxCarbAmountKey) as? Int else {
            return 50
        }
        return maxCarbAmount
    }
    
    @objc dynamic var maxBolusAmount: Int {
        guard let maxBolus = object(forKey: maxBolusAmountKey) as? Int else {
            return 10
        }
        return maxBolus
    }
    
    @objc dynamic var disclaimerAcceptedDate: Date? {
        guard let date = object(forKey: disclaimerAcceptedDateKey) as? Date else {
            return nil
        }

        return date
    }
}

@objc public enum GlucoseUnitPrefererence: Int, Codable, CaseIterable {
    case milligramsPerDeciliter
    case millimolesPerLiter
    
    public var presentableDescription: String {
        switch self {
        case .milligramsPerDeciliter:
            return "mg/dL"
        case .millimolesPerLiter:
            return "mmol/L"
        }
    }
    
    public var unit: HKUnit {
        switch self {
        case .milligramsPerDeciliter:
            return .milligramsPerDeciliter
        case .millimolesPerLiter:
            return .millimolesPerLiter
        }
    }
}
