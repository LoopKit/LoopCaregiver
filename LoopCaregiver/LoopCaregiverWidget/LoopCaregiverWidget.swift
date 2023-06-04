//
//  LoopCaregiverWidget.swift
//  LoopCaregiverWidget
//
//  Created by Bill Gestrich on 6/1/23.
//

import WidgetKit
import SwiftUI
import Intents

struct LoopCaregiverWidget: Widget {
    
    let kind: String = "LoopCaregiverWidget"
    let timelineProvider = TimelineProvider()
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: timelineProvider) { entry in
            LoopCaregiverWidgetView(entry: entry)
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
        let entry = SimpleEntry(looper: Looper(name: "Test", nightscoutCredentials: nsCredentials, lastSelectedDate: Date()), currentGlucoseSample: .none, lastGlucoseChange: 0.0, date: Date(), entryIndex: 0, configuration: ConfigurationIntent())
        return LoopCaregiverWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
