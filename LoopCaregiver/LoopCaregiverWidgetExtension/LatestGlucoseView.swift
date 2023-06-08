//
//  LatestGlucoseView.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/3/23.
//

import SwiftUI
import LoopKit
import HealthKit

struct LatestGlucoseView: View {
    
    let timelineEntryDate: Date
    let latestGlucose: NewGlucoseSample
    let lastGlucoseChange: Double?
    let settings: CaregiverSettings
    let isLastEntry: Bool
    
    var body: some View {
        VStack {
            Text(currentGlucoseDateText)
                .strikethrough(isGlucoseStale)
                .font(.footnote)
            Text(currentGlucoseText)
                .strikethrough(isGlucoseStale)
                .font(.headline)
                .bold()
            if let currentTrendImageName {
                Image(systemName: currentTrendImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 15)
                    .offset(.init(width: 0.0, height: -7.0))
            }
        }
    }
    
    var currentGlucoseDateText: String {
        if isLastEntry {
            return ""
        }
        let elapsedMinutes: Double = timelineEntryDate.timeIntervalSince(latestGlucose.date) / 60.0
        let roundedMinutes = Int(exactly: elapsedMinutes.rounded(.up)) ?? 0
        return "\(roundedMinutes)m"
//        return timeFormat.string(from: latestGlucose.date) + " (\(elapsedMinutes)m)"
    }
    
    var isGlucoseStale: Bool {
        return latestGlucose.date < timelineEntryDate.addingTimeInterval(-60*15)
    }
    
    var currentGlucoseText: String {
        var toRet = ""
        let latestGlucoseValue = latestGlucose.presentableStringValue(displayUnits: settings.glucoseDisplayUnits)
        toRet += "\(latestGlucoseValue)"
        
        if let lastGlucoseChangeFormatted = lastGlucoseChangeFormatted  {
            toRet += " \(lastGlucoseChangeFormatted)"
        }
        
        return toRet
    }
    
    var lastGlucoseChangeFormatted: String? {
        
        guard let lastGlucoseChange else {return nil}
        
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
    
    var currentTrendImageName: String? {
        
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
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    
}

struct CurrentBGView_Previews: PreviewProvider {
    static var previews: some View {
        LatestGlucoseView(timelineEntryDate: Date(), latestGlucose: NewGlucoseSample(date: Date(), quantity: .init(unit: .internationalUnitsPerHour, doubleValue: 1.0), condition: .aboveRange, trend: .down, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "12345"), lastGlucoseChange: 3, settings: CaregiverSettings(), isLastEntry: true)
    }
}
