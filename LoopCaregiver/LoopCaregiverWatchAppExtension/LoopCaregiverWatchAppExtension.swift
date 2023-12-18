//
//  LoopCaregiverWatchAppExtension.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 10/27/23.
//

import LoopCaregiverKit
import LoopKit
import WidgetKit
import SwiftUI

@main
struct LoopCaregiverWatchAppExtension: Widget {
    let kind: String = "LoopCaregiverWatchAppExtension"
    let provider = TimelineProvider()

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: provider) { entry in
            if let latestGlucose = entry.currentGlucoseSample {
                //TODO: It is not clear if setting changes will propogate from the Caregiver watch app
                LatestGlucoseView(timelineEntryDate: entry.date, latestGlucose: latestGlucose, lastGlucoseChange: nil, settings: provider.composer.settings, isLastEntry: false)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                Text("??")
            }

//            LoopCaregiverWatchAppExtensionEntryView(entry: entry)
//                .containerBackground(.fill.tertiary, for: .widget)
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
    SimpleEntry(currentGlucoseSample: NewGlucoseSample(date: Date(), quantity: .init(unit: .milligramsPerDeciliter, doubleValue: 100.0), condition: .none, trend: .flat, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "1345"), lastGlucoseChange: nil, date: .now, entryIndex: 0, isLastEntry: false)
}
