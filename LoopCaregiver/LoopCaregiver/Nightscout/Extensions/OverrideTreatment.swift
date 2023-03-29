//
//  OverrideTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 2/18/23.
//

import Foundation
import NightscoutKit

extension OverrideTreatment: Equatable {
    public static func == (lhs: NightscoutKit.OverrideTreatment, rhs: NightscoutKit.OverrideTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.endDate == rhs.endDate &&
        lhs.correctionRange == rhs.correctionRange &&
        lhs.insulinNeedsScaleFactor == rhs.insulinNeedsScaleFactor &&
        lhs.reason == rhs.reason &&
        lhs.remoteAddress == rhs.remoteAddress
    }
}
