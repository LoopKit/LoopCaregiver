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
}

