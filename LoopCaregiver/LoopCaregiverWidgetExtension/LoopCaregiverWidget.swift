//
//  LoopCaregiverWidget.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/1/23.
//

import Intents
import LoopCaregiverKit
import SwiftUI
import WidgetKit

struct LoopCaregiverWidget: Widget {
    
    let kind: String = "LoopCaregiverWidget"
    let timelineProvider = TimelineProvider()
    let composer = ServiceComposerProduction()
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: timelineProvider) { entry in
            LoopCaregiverWidgetView(entry: entry, settings: composer.settings)
        }
        .configurationDisplayName("Loop Caregiver")
        .description("Displays Looper's last BG.")
        .supportedFamilies([
//            .accessoryRectangular,
//            .accessoryInline,
            .accessoryCircular,
            .systemSmall,
//            .systemMedium,
//            .systemLarge,
//            .systemExtraLarge
        ])
    }
}

struct LoopCaregiverWidget_Previews: PreviewProvider {
    static var previews: some View {
        let nsCredentials = NightscoutCredentials(url: URL(string: "https://wwww.sample.com")!, secretKey: "12345", otpURL: "12345")
        let entry = SimpleEntry( looper: Looper(identifier: UUID(), name: "Test", nightscoutCredentials: nsCredentials, lastSelectedDate: Date()), currentGlucoseSample: .none, lastGlucoseChange: 0.0, date: Date(), entryIndex: 0, isLastEntry: true)
        let composer = ServiceComposerPreviews()
        return LoopCaregiverWidgetView(entry: entry, settings: composer.settings)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
