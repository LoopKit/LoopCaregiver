//
//  LoopCaregiverWidgetView.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation
import LoopCaregiverKit
import LoopCaregiverKitUI
import SwiftUI

struct LoopCaregiverWidgetView : View {
    
    @ObservedObject var settings: CaregiverSettings
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    
    init(entry: SimpleEntry, settings: CaregiverSettings){
        self.entry = entry
        //TODO: Settings changes from the app don't seem to propogate here
        //requiring a device reboot after changing the active Looper, for instance.
        self.settings = settings
    }
    
    var widgetURL: URL {
        if let looper = entry.looper {
            let deepLink = SelectLooperDeepLink(looperUUID: looper.id)
            return URL(string: deepLink.toURL())!
        } else {
            let deepLink = SelectLooperDeepLink(looperUUID: "")
            return URL(string: deepLink.toURL())!
        }

    }

    var body: some View {
        Group {
            if settings.appGroupsSupported {
                switch family {
                case .accessoryCircular:
                    if let latestGlucoseSample = entry.currentGlucoseSample {
                        LatestGlucoseCircularView(viewModel: WidgetViewModel(timelineEntryDate: entry.date, latestGlucose: latestGlucoseSample, lastGlucoseChange: entry.lastGlucoseChange, isLastEntry: entry.isLastEntry, glucoseDisplayUnits: settings.glucoseDisplayUnits))
                    } else {
                        emptyLatestGlucoseView
                    }
                default:
                    defaultView
                }
            } else {
                switch family {
                case .accessoryCircular:
                   Text("AppGroups?")
                default:
                    Text("Widgets require App Groups via Xcode Builds.")
                }
            }
        }
        .widgetBackground(backgroundView: backgroundView)
        .widgetURL(widgetURL)
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
                LatestGlucoseCircularView(viewModel: WidgetViewModel(timelineEntryDate: entry.date, latestGlucose: latestGlucoseSample, lastGlucoseChange: entry.lastGlucoseChange, isLastEntry: entry.isLastEntry, glucoseDisplayUnits: settings.glucoseDisplayUnits))
            } else {
                emptyLatestGlucoseView
            }
//            if experimentalFeaturesUnlocked {
//                if let lastGlucoseDate = entry.currentGlucoseSample?.date {
//                    Text(timeFormat.string(from: lastGlucoseDate))
//                        .font(.footnote)
//                }
//                Text("\(timeFormat.string(from: entry.date)) (\(entry.entryIndex))")
//                    .font(.footnote)
//            }
        }
    }
    
    var backgroundView: some View {
        Color.clear
    }
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}

extension View {
    //Remove this when iOS 17 is minimum required
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
