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
    
    @ObservedObject var accountService: AccountServiceManager
    @AppStorage("lastPhoneDebugMessage", store: UserDefaults(suiteName: Bundle.main.appGroupSuiteName)) var lastPhoneDebugMessage: String = ""
    @State private var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    @ObservedObject var settings: CaregiverSettings
    var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        VStack {
            //Text(lastPhoneDebugMessage)
            Form {
                Picker("Glucose", selection: $glucosePreference, content: {
                    ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                        Text(item.presentableDescription).tag(item)
                    })
                })
                Section("Loopers") {
                    List(accountService.loopers, id: \.id) { looper in
                        Text(looper.name)
                    }
                }
            }
        }
        .navigationTitle("Settings")
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
        WidgetCenter.shared.reloadAllTimelines()
    }
}
