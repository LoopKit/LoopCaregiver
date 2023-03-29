//
//  TempBasalNightscoutTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

extension TempBasalNightscoutTreatment: Equatable {
    public static func == (lhs: NightscoutKit.TempBasalNightscoutTreatment, rhs: NightscoutKit.TempBasalNightscoutTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.amount == rhs.amount &&
        lhs.duration == rhs.duration &&
        lhs.rate == rhs.rate &&
        lhs.absolute == rhs.absolute &&
        lhs.automatic == rhs.automatic
    }
}
