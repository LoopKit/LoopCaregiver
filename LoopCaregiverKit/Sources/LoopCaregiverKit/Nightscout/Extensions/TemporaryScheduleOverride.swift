//
//  TemporaryScheduleOverride.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

public extension TemporaryScheduleOverride {
    
    func durationInMinutes() -> Int {
        return Int(duration / 60)
    }
    
    func presentableDescription() -> String {
        return "\(symbol ?? "") \(name ?? "")"
    }
    
    func targetRangePresentableDescription() -> String? {
        guard let targetRange else { return nil }
        return "\(Int(targetRange.lowerBound)) - \(Int(targetRange.upperBound))"
    }
}

public extension OverrideStatus {
    func endTimeDescription() -> String? {
        guard let duration, duration < 60 * 60 * 24 else { return nil }
        let endDate = timestamp.addingTimeInterval(duration)
        let endTimeText = DateFormatter.localizedString(from: endDate, dateStyle: .none, timeStyle: .short)
        return String(format: NSLocalizedString("until %@", comment: "The format for the description of a custom preset end date"), endTimeText)
    }
}

extension TemporaryScheduleOverride: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    
     public static func == (lhs: TemporaryScheduleOverride, rhs: TemporaryScheduleOverride) -> Bool {
         /*
          TODO:
          Only using the name so this can work in SwiftUI Identifiable protocol
          The other properties for the "seelcted" TemporaryScheduleOverride will
          have other properties that vary.
          
          Look into what properties vary in the selected TemporaryScheduleOverride
          vs the list that we get back.
          
          It seems like we should be able to a custom Identifiable implementation that uses
          name and allow the == method to check all properties. This didn't work when experimenting though.
          */
         lhs.name == rhs.name
//         lhs.symbol == rhs.symbol &&
//         lhs.duration == rhs.duration &&
//         lhs.targetRange == rhs.targetRange &&
//         lhs.insulinNeedsScaleFactor == rhs.insulinNeedsScaleFactor
     }
     
}
