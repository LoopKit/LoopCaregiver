//
//  SettingsView.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 12/26/23.
//

import LoopCaregiverKit
import SwiftUI
import WidgetKit

struct SettingsView: View {
    
    @AppStorage("lastPhoneDebugMessage", store: UserDefaults(suiteName: Bundle.main.appGroupSuiteName)) var lastPhoneDebugMessage: String = ""
    @State private var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    @ObservedObject var settings: CaregiverSettings
    
    var body: some View {
        VStack {
            //Text(lastPhoneDebugMessage)
            Form {
                Picker("Glucose", selection: $glucosePreference, content: {
                    ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                        Text(item.presentableDescription).tag(item)
                    })
                })
            }
        }
        .navigationTitle("Diagnostics")
        .onAppear {
            self.glucosePreference = settings.glucoseUnitPreference
        }
        .onChange(of: glucosePreference, {
            if settings.glucoseUnitPreference != glucosePreference {
                settings.saveGlucoseUnitPreference(glucosePreference)
                reloadWidget()
            }
        })
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "LoopCaregiverWatchAppExtension")
    }
}
