//
//  LoopCaregiverWatchAppExtension.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 10/27/23.
//

import HealthKit
import LoopCaregiverKit
import LoopCaregiverKitUI
import LoopKit
import SwiftUI
import WidgetKit

@main
struct LoopCaregiverWatchAppExtension: Widget {
    
    let kind: String = "LoopCaregiverWatchAppExtension"
    let provider = TimelineProvider()

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: provider) { entry in
            Group {
                if let latestGlucose = entry.currentGlucoseSample {
                    WidgetView(viewModel: widgetViewModel(entry: entry, latestGlucose: latestGlucose))
                } else {
                    Text("??")
                }
            }.widgetURL(widgetURL(looper: entry.looper))
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
    
    func widgetURL(looper: Looper?) -> URL {
        if let looper = looper {
            let deepLink = SelectLooperDeepLink(looperUUID: looper.id)
            return deepLink.toURL()
        } else {
            let deepLink = SelectLooperDeepLink(looperUUID: "")
            return deepLink.toURL()
        }
    }
    
    func widgetViewModel(entry: SimpleEntry, latestGlucose: NewGlucoseSample) -> WidgetViewModel {
        return WidgetViewModel(timelineEntryDate: entry.date, latestGlucose: latestGlucose, lastGlucoseChange: entry.lastGlucoseChange, isLastEntry: entry.isLastEntry, glucoseDisplayUnits: entry.glucoseDisplayUnits, looper: entry.looper)
    }
    
    func widgetURL(entry: SimpleEntry) -> URL {
        if let looper = entry.looper {
            let deepLink = SelectLooperDeepLink(looperUUID: looper.id)
            return deepLink.toURL()
        } else {
            let deepLink = SelectLooperDeepLink(looperUUID: "")
            return deepLink.toURL()
        }

    }

}

struct WidgetView: View {
    
    var viewModel: WidgetViewModel
    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryInline:
            LatestGlucoseInlineView(viewModel: viewModel)
        default:
            LatestGlucoseCircularView(viewModel: viewModel)
        }
    }
}

#Preview(as: .accessoryRectangular) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    SimpleEntry(looper: nil, currentGlucoseSample: NewGlucoseSample.placeholder(), lastGlucoseChange: nil, date: .now, entryIndex: 0, isLastEntry: false, glucoseDisplayUnits: .milligramsPerDeciliter)
}

#Preview(as: .accessoryInline) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    SimpleEntry(looper: nil, currentGlucoseSample: NewGlucoseSample.placeholder(), lastGlucoseChange: nil, date: .now, entryIndex: 0, isLastEntry: false, glucoseDisplayUnits: .milligramsPerDeciliter)
}
