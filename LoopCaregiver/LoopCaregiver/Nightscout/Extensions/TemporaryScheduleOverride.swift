//
//  TemporaryScheduleOverride.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutUploadKit

extension TemporaryScheduleOverride {
    
    func durationInMinutes() -> Int {
        return Int(duration / 60)
    }
    
    func presentableDescription() -> String {
        return "\(symbol ?? "") \(name ?? "")"
    }
}

extension TemporaryScheduleOverride: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public static func == (lhs: TemporaryScheduleOverride, rhs: TemporaryScheduleOverride) -> Bool {
        lhs.name == rhs.name &&
        lhs.symbol == rhs.symbol &&
        lhs.duration == rhs.duration &&
        lhs.targetRange == rhs.targetRange &&
        lhs.insulinNeedsScaleFactor == rhs.insulinNeedsScaleFactor
    }
}
