//
//  ConfigurationAppIntent.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 10/27/23.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Caregiver Watch App")

    @Parameter(title: "LooperID")
    var looperID: String?

    @Parameter(title: "Name")
    var name: String?
    
    init() {
    }
    
    init(looperID: String?, name: String?) {
        self.looperID = looperID
        self.name = name
    }
}
