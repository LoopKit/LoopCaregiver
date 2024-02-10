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
    
    @ObservedObject var connectivityManager: WatchSession
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var settings: CaregiverSettings
    
    @AppStorage("lastPhoneDebugMessage", store: UserDefaults(suiteName: Bundle.main.appGroupSuiteName)) var lastPhoneDebugMessage: String = ""
    @State private var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        VStack {
            Form {
                Picker("Glucose", selection: $glucosePreference, content: {
                    ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                        Text(item.presentableDescription).tag(item)
                    })
                })
                Section("Loopers") {
                    List {
                        ForEach(accountService.loopers, id: \.id) { looper in
                            Text(looper.name)
                        }
                        .onDelete(perform: delete)
                    }
                }
                Section("Phone Connectivity") {
                    LabeledContent("Session Supported", value: connectivityManager.sessionsSupported() ? "YES" : "NO")
                    LabeledContent("Session Activated", value: connectivityManager.activated ? "YES" : "NO")
                    LabeledContent("Companion App Inst", value: connectivityManager.isCounterpartAppInstalled() ? "YES" : "NO")
                    LabeledContent("Phone Reachable", value: connectivityManager.isReachable() ? "YES" : "NO")
                    LabeledContent("Last Msg Date", value: connectivityManager.notificationMessage?.receivedDate.description ?? "")
                }
                Section("Widgets") {
                    Button(action: {
                        WidgetCenter.shared.invalidateConfigurationRecommendations()
                    }, label: {
                        Text("Invalidate Recommendations")
                    })
                    Button(action: {
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    }, label: {
                        Text("Reload Timeline")
                    })
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
    
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let looper = accountService.loopers[index]
            do {
                try accountService.removeLooper(looper)
            } catch {
                print("Could not delete looper. \(looper), Error: \(error)")
            }

        }

    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
