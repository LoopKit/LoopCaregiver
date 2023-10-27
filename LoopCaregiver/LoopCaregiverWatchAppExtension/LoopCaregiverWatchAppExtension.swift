//
//  LoopCaregiverWatchAppExtension.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 10/27/23.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Loop Caregiver Widget")]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct LoopCaregiverWatchAppExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                Text("Time:")
                Text(entry.date, style: .time)
            }
        
            Text("Caregiver Watch App:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

@main
struct LoopCaregiverWatchAppExtension: Widget {
    let kind: String = "LoopCaregiverWatchAppExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            LoopCaregiverWatchAppExtensionEntryView(entry: entry)
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
    SimpleEntry(date: .now, configuration: .smiley)
}    
