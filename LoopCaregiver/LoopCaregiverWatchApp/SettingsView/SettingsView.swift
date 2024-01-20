//
//  SettingsView.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 12/26/23.
//

import LoopCaregiverKit
import SwiftUI
import WatchConnectivity
import WidgetKit

struct SettingsView: View {
    
    @ObservedObject var connectivityManager: WatchConnectivityManager
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
                    Text("Session Supported: \(WCSession.isSupported().description)")
                    Text("Session State: \(WCSession.default.activationState.description())")
                    Text("Companion App Inst: \(WCSession.default.isCompanionAppInstalled.description)")
                    LabeledContent("Phone Reachable", value: WCSession.default.isReachable ? "YES" : "NO")
                    Text("Last Msg Date: \(connectivityManager.notificationMessage?.receivedDate.description ?? "")")
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
        for idex in offsets {
            let looper = accountService.loopers[idex]
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
