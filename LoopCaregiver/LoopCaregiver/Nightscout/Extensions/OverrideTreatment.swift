//
//  OverrideTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 2/18/23.
//

import Foundation
import NightscoutUploadKit

extension OverrideTreatment: Equatable {
    public static func == (lhs: NightscoutUploadKit.OverrideTreatment, rhs: NightscoutUploadKit.OverrideTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.endDate == rhs.endDate &&
        lhs.correctionRange == rhs.correctionRange &&
        lhs.insulinNeedsScaleFactor == rhs.insulinNeedsScaleFactor &&
        lhs.reason == rhs.reason &&
        lhs.remoteAddress == rhs.remoteAddress
    }
}
