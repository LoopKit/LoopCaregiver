//
//  NewGlucoseSample+Presentable.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 6/3/23.
//

import Foundation
import HealthKit
import LoopKit

public extension NewGlucoseSample {
    
    func presentableUserValue(displayUnits: HKUnit) -> Double {
        return quantity.doubleValue(for: displayUnits)
    }
    
    func presentableStringValue(displayUnits: HKUnit) -> String {
        let unitInUserUnits = quantity.doubleValue(for: displayUnits)
        return LocalizationUtils.presentableStringFromGlucoseAmount(unitInUserUnits, displayUnits: displayUnits)
    }
    
    func presentableStringValueWithUnits(displayUnits: HKUnit) -> String {
        if displayUnits == .milligramsPerDeciliter {
            return "\(presentableStringValue(displayUnits: displayUnits)) mg/dL"
        } else if displayUnits == .millimolesPerLiter {
            return "\(presentableStringValue(displayUnits: displayUnits)) mmol/L"
        } else {
            return "Error: Missing units"
        }
    }
}
