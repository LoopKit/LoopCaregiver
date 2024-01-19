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
            if let latestGlucose = entry.currentGlucoseSample {
                WidgetView(viewModel: widgetViewModel(entry: entry, latestGlucose: latestGlucose))
            } else {
                Text("??")
            }
        }
    }
    
    func widgetViewModel(entry: SimpleEntry, latestGlucose: NewGlucoseSample) -> WidgetViewModel {
        return WidgetViewModel(timelineEntryDate: entry.date, latestGlucose: latestGlucose, lastGlucoseChange: entry.lastGlucoseChange, isLastEntry: entry.isLastEntry, glucoseDisplayUnits: entry.glucoseDisplayUnits)
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
                .containerBackground(.fill.tertiary, for: .widget)
        default:
            LatestGlucoseCircularView(viewModel: viewModel)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
}

#Preview(as: .accessoryRectangular) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    SimpleEntry(currentGlucoseSample: NewGlucoseSample(date: Date(), quantity: .init(unit: .milligramsPerDeciliter, doubleValue: 100.0), condition: .none, trend: .flat, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "1345"), lastGlucoseChange: nil, date: .now, entryIndex: 0, isLastEntry: false, glucoseDisplayUnits: .milligramsPerDeciliter)
}

#Preview(as: .accessoryInline) {
    LoopCaregiverWatchAppExtension()
} timeline: {
    SimpleEntry(currentGlucoseSample: NewGlucoseSample(date: Date(), quantity: .init(unit: .milligramsPerDeciliter, doubleValue: 100.0), condition: .none, trend: .flat, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "1345"), lastGlucoseChange: nil, date: .now, entryIndex: 0, isLastEntry: false, glucoseDisplayUnits: .milligramsPerDeciliter)
}
