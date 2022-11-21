//
//  NightscoutService+Credentials.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/21/22.
//

import Foundation
import NightscoutClient

extension NightscoutEGV: Equatable {
    public static func == (lhs: NightscoutEGV, rhs: NightscoutEGV) -> Bool {
        return lhs.displayTime == rhs.displayTime &&
        lhs.systemTime == rhs.displayTime &&
        lhs.value == rhs.value
    }
}

extension NightscoutEGV: Identifiable {
    public var id: Date {
        return displayTime
    }
}

extension WGCarbEntry: Equatable {
    public static func == (lhs: NightscoutClient.WGCarbEntry, rhs: NightscoutClient.WGCarbEntry) -> Bool {
        return lhs.amount == rhs.amount &&
        lhs.date == rhs.date
    }
}

extension WGBolusEntry: Equatable {
    public static func == (lhs: WGBolusEntry, rhs: WGBolusEntry) -> Bool {
        return lhs.amount == rhs.amount &&
        lhs.date == rhs.date
    }
}
