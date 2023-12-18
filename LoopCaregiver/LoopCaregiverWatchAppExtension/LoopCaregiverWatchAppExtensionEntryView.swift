//
//  LoopCaregiverWatchAppExtensionEntryView.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 12/18/23.
//

import SwiftUI

struct LoopCaregiverWatchAppExtensionEntryView : View {
    var entry: TimelineProvider.Entry
    var userDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)!

    var body: some View {
        VStack {
            Text(valueDecription)
            Text(dateDescription)
        }
    }
    
    var valueDecription: String {
        guard let value = entry.currentGlucoseSample?.quantity.doubleValue(for: .milligramsPerDeciliter) else {
            return ""
        }
        
        return "\(Int(value))"
    }
    
    var dateDescription: String {
        guard let date = entry.currentGlucoseSample?.date else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    var lastPhoneDebugMessage: String {
        if let message = userDefaults.lastPhoneDebugMessage {
            return message
        } else {
            return "?"
        }
    }

}
