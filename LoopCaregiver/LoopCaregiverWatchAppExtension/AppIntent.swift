//
//  AppIntent.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 10/27/23.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Caregiver Watch App Intent.")

    // An example configurable parameter.
    @Parameter(title: "Support Coming Soon", default: "😃")
    var favoriteEmoji: String
}
