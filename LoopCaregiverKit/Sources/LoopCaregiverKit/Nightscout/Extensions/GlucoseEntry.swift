//
//  GlucoseEntry.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit
import LoopKit
import HealthKit

public extension GlucoseEntry {
    func toGlucoseSample() -> NewGlucoseSample {
        
        let glucoseTrend: LoopKit.GlucoseTrend?
        if let trend = trend {
            glucoseTrend = LoopKit.GlucoseTrend(rawValue: trend.rawValue)
        } else {
            glucoseTrend = nil
        }
        
        return NewGlucoseSample(
            date: startDate,
            quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: glucose),
            condition: nil,
            trend: glucoseTrend,
            trendRate: trendRate,
            isDisplayOnly: isCalibration == true,
            wasUserEntered: glucoseType == .meter,
            syncIdentifier: id ?? "\(Int(startDate.timeIntervalSince1970))",
            device: nil)
    }
}

extension GlucoseEntry: GlucoseValue {
    public var startDate: Date { date }
    public var quantity: HKQuantity { .init(unit: .milligramsPerDeciliter, doubleValue: glucose) }
}

extension GlucoseEntry: GlucoseDisplayable {

    public var isStateValid: Bool {
        glucoseType == .meter || glucose >= 39
    }
    
    public var trendType: LoopKit.GlucoseTrend? {
        if let trend = trend {
            return LoopKit.GlucoseTrend(rawValue: trend.rawValue)
        } else {
            return nil
        }
    }

    public var isLocal: Bool { false }
    
    // TODO Placeholder. This functionality will come with LOOP-1311
    public var glucoseRangeCategory: GlucoseRangeCategory? {
        return nil
    }

    public var trendRate: HKQuantity? {
        
        guard let changeRate = changeRate else {
            return nil
        }
        
        return HKQuantity(unit: .milligramsPerDeciliterPerMinute, doubleValue: changeRate)
    }
}
