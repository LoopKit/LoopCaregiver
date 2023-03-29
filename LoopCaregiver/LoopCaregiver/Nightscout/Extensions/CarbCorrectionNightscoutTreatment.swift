//
//  CarbCorrectionNightscoutTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit
import HealthKit

extension CarbCorrectionNightscoutTreatment {
    func graphItem(egvValues: [GraphItem], displayUnit: HKUnit) -> GraphItem {
        let relativeEgvValue = interpolateEGVValue(egvs: egvValues, atDate: timestamp)
        return GraphItem(type: .carb(self), displayTime: timestamp, quantity: HKQuantity(unit: displayUnit, doubleValue: relativeEgvValue), displayUnit: displayUnit)
    }
}

extension CarbCorrectionNightscoutTreatment: Equatable {
    public static func == (lhs: NightscoutKit.CarbCorrectionNightscoutTreatment, rhs: NightscoutKit.CarbCorrectionNightscoutTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.carbs == rhs.carbs
    }
}
