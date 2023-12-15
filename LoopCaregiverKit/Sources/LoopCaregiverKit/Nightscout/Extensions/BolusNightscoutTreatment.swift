//
//  BolusNightscoutTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

extension BolusNightscoutTreatment: Equatable {
    public static func == (lhs: NightscoutKit.BolusNightscoutTreatment, rhs: NightscoutKit.BolusNightscoutTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.duration == rhs.duration &&
        lhs.amount == rhs.amount
    }
}
