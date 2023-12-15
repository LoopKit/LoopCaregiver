//
//  CarbCorrectionNightscoutTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

extension CarbCorrectionNightscoutTreatment: Equatable {
    public static func == (lhs: NightscoutKit.CarbCorrectionNightscoutTreatment, rhs: NightscoutKit.CarbCorrectionNightscoutTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.carbs == rhs.carbs
    }
}
