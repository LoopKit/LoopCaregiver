//
//  WidgetViewModel.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/2/24.
//

import Foundation
import HealthKit
import LoopKit
import SwiftUI

public struct WidgetViewModel {
    
    public let timelineEntryDate: Date
    public let latestGlucose: NewGlucoseSample
    public let lastGlucoseChange: Double?
    public let isLastEntry: Bool
    public let glucoseDisplayUnits: HKUnit
    
    public init(timelineEntryDate: Date, latestGlucose: NewGlucoseSample, lastGlucoseChange: Double? = nil, isLastEntry: Bool, glucoseDisplayUnits: HKUnit) {
        self.timelineEntryDate = timelineEntryDate
        self.latestGlucose = latestGlucose
        self.lastGlucoseChange = lastGlucoseChange
        self.isLastEntry = isLastEntry
        self.glucoseDisplayUnits = glucoseDisplayUnits
    }
    
    public var currentGlucoseDateText: String {
        if isLastEntry {
            return ""
        }
        let elapsedMinutes: Double = timelineEntryDate.timeIntervalSince(latestGlucose.date) / 60.0
        let roundedMinutes = Int(exactly: elapsedMinutes.rounded(.up)) ?? 0
        return "\(roundedMinutes)m"
    }
    
    public var isGlucoseStale: Bool {
        return latestGlucose.date < timelineEntryDate.addingTimeInterval(-60*15)
    }
    
    public var currentGlucoseText: String {
        var toRet = ""
        let latestGlucoseValue = latestGlucose.presentableStringValue(displayUnits: glucoseDisplayUnits)
        toRet += "\(latestGlucoseValue)"
        
        if let lastGlucoseChangeFormatted = lastGlucoseChangeFormatted  {
            toRet += " \(lastGlucoseChangeFormatted)"
        }
        
        return toRet
    }
    
    public var lastGlucoseChangeFormatted: String? {
        
        guard let lastGlucoseChange = lastGlucoseChange else {return nil}
        
        guard lastGlucoseChange != 0 else {return nil}
        
        let formatter = NumberFormatter()
        formatter.positivePrefix = "+"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        
        guard let formattedGlucoseChange = formatter.string(from: lastGlucoseChange as NSNumber) else {
            return nil
        }
        
        return formattedGlucoseChange
        
    }
    
    public var currentTrendImageName: String? {
        
        guard let trend = latestGlucose.trend else {
            return nil
        }
        
        switch trend {
            
        case .up:
            return "arrow.up.forward"
        case .upUp:
            return "arrow.up"
        case .upUpUp:
            return "arrow.up"
        case .flat:
            return "arrow.right"
        case .down:
            return "arrow.down.forward"
        case .downDown:
            return "arrow.down"
        case .downDownDown:
            return "arrow.down"
        }
    }
    
    public var egvValueColor: Color {
        return ColorType(quantity: latestGlucose.quantity).color
    }
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    
}
