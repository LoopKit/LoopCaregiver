//
//  LoopKit+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/25/22.
//

import Foundation
import LoopKit

extension NewGlucoseSample {
    func graphItem() -> GraphItem {
        return GraphItem(type: .egv, value: intValue(), displayTime: date)
    }
    
    func intValue() -> Int {
        return Int(quantity.doubleValue(for: .milligramsPerDeciliter)) //TODO: Crash Potential
    }
    
    func presentableStringValue() -> String {
        let unitInUserUnits = quantity.doubleValue(for: CaregiverSetttings.glucoseUnits())
        if CaregiverSetttings.glucoseUnits() == .milligramsPerDeciliter {
            return String(format: "%.0f", unitInUserUnits)
        } else if CaregiverSetttings.glucoseUnits() == .millimolesPerLiter {
            return String(format: "%.1f", unitInUserUnits)
        } else {
            return "Error: Unknown units"
        }
    }
    
    func presentableStringValueWithUnits() -> String {
        if CaregiverSetttings.glucoseUnits() == .milligramsPerDeciliter {
            return "\(presentableStringValue()) mg/dL"
        } else if CaregiverSetttings.glucoseUnits() == .millimolesPerLiter {
            return "\(presentableStringValue()) mmol/L"
        } else {
            return "Error: Missing units"
        }
    }
}
