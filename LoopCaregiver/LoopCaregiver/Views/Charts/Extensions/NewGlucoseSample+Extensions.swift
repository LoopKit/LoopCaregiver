//
//  NewGlucoseSample+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/25/22.
//

import Foundation
import LoopKit
import HealthKit


//Loop Charts
extension NewGlucoseSample: GlucoseValue {
    public var startDate: Date {
        return date
    }
}


//Nightscout Graph
extension NewGlucoseSample {
    func graphItem(displayUnit: HKUnit) -> GraphItem {
        return GraphItem(type: .egv, displayTime: date, quantity: quantity, displayUnit: displayUnit)
    }
    
    func predictedBGGraphItem(displayUnit: HKUnit) -> GraphItem {
        return GraphItem(type: .predictedBG, displayTime: date, quantity: quantity, displayUnit: displayUnit)
    }
    
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

