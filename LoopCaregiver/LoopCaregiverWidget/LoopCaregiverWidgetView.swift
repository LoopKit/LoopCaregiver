//
//  LoopCaregiverWidgetView.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation
import SwiftUI

struct LoopCaregiverWidgetView : View {
    
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    
    init(entry: SimpleEntry){
        self.entry = entry
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            if let latestGlucoseSample = entry.currentGlucoseSample {
                LatestGlucoseView(timelineEntryDate: entry.date, latestGlucose: latestGlucoseSample, lastGlucoseChange: entry.lastGlucoseChange, settings: CaregiverSettings())
            } else {
                emptyLatestGlucoseView
            }
        default:
            defaultView
        }
    }
    
    var emptyLatestGlucoseView: some View {
        VStack {
            Text("---")
            Text("---")
        }
    }
    
    var defaultView: some View {
        VStack {
            if let looper = entry.looper {
                Text(looper.name)
                    .font(.headline)
            }
            if let latestGlucoseSample = entry.currentGlucoseSample {
                LatestGlucoseView(timelineEntryDate: entry.date, latestGlucose: latestGlucoseSample, lastGlucoseChange: entry.lastGlucoseChange, settings: CaregiverSettings())
            } else {
                emptyLatestGlucoseView
            }
//            Text("\(timeFormat.string(from: entry.date)) (\(entry.entryIndex))")
//                .font(.footnote)
        }
    }
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}

