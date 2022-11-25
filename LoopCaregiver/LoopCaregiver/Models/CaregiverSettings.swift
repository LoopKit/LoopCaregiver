//
//  CaregiverSettings.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/25/22.
//

import Foundation
import HealthKit

struct CaregiverSetttings {
    static func glucoseUnits() -> HKUnit {
        
        //International standard: millimoles per liter (mM)
        //US/Canada: milligrams per decilitre (mg/dL)
        
        return .milligramsPerDeciliter
//        return .millimolesPerLiter
    }
}
