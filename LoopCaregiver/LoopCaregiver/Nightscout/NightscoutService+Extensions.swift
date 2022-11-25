//
//  NightscoutService+Credentials.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/21/22.
//

import Foundation
import NightscoutClient
import LoopKit
import HealthKit

extension NightscoutEGV {
    func toGlucoseSample() -> NewGlucoseSample {
        return NewGlucoseSample(date: self.systemTime,
                                quantity: valueHKQuantity(),
                                condition: nil,
                                trend: glucoseTrend(),
                                trendRate: trendRateHKQuantity(),
                                isDisplayOnly: false,
                                wasUserEntered: false,
                                syncIdentifier:  _id)
    }
    
    func valueHKQuantity() -> HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(value))
    }
    
    func glucoseTrend() -> GlucoseTrend? {
        
        guard let trendRate = self.trendRate else {
            return nil
        }
        
        guard let trendRateAsInt = Int(exactly: trendRate) else {
            return nil
        }
        
        return GlucoseTrend(rawValue: trendRateAsInt)
    }
    
    func trendRateHKQuantity() -> HKQuantity? {
        
        guard let glucoseTrendRate = glucoseTrend() else {
            return nil
        }
        
        let value = Double(glucoseTrendRate.rawValue)
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: value)
    }
}

extension NightscoutEGV: Equatable {
    public static func == (lhs: NightscoutEGV, rhs: NightscoutEGV) -> Bool {
        return lhs._id == rhs._id
    }
}

extension NightscoutEGV: Identifiable {
    public var id: String {
        return _id
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

extension WGLoopCOB: Equatable {
    public static func == (lhs: WGLoopCOB, rhs: WGLoopCOB) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.cob == rhs.cob
    }
}

extension WGLoopIOB: Equatable {
    public static func == (lhs: WGLoopIOB, rhs: WGLoopIOB) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.iob == rhs.iob
    }
}
