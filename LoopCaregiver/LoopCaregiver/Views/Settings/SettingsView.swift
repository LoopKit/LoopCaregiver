//
//  SettingsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var accountService: AccountServiceManager
    @AppStorage(UserDefaults.appGroupDefaults.glucoseUnitKey, store: UserDefaults.appGroupDefaults) var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    @AppStorage(UserDefaults.appGroupDefaults.timelinePredictionEnabledKey, store: UserDefaults.appGroupDefaults) private var timelinePredictionEnabled = false
    @AppStorage(UserDefaults.appGroupDefaults.remoteCommands2EnabledKey, store: UserDefaults.appGroupDefaults) private var remoteCommands2Enabled = false
    @AppStorage(UserDefaults.appGroupDefaults.experimentalFeaturesUnlockedKey, store: UserDefaults.appGroupDefaults) private var experimentalFeaturesUnlocked = false
    
    @ObservedObject var settings: CaregiverSettings
    @Binding var showSheetView: Bool
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            Form {
                loopersSection
                unitsSection
                timelineSection
                experimentalSection
            }
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.showSheetView = false
            }) {
                Text("Done").bold()
            })
            .navigationDestination(
                for: LooperService.self
            ) { looperService in
                LooperView(looperService: looperService,
                           nightscoutCredentialService: NightscoutCredentialService(credentials: looperService.looper.nightscoutCredentials),
                           remoteDataSource: looperService.remoteDataSource,
                           looper: looperService.looper,
                           path: $path)
            }
            .navigationDestination(
                for: String.self
            ) { val in
                LooperSetupView(accountService: accountService, settings: settings, path: $path)
            }
        }
    }
    
    var loopersSection: some View {
        Section("Loopers"){
            List(accountService.loopers) { looper in
                looperRowView(looper: looper)
            }
            NavigationLink(value: "AddLooper") {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                    Text("Add New Looper")
                }
            }
        }
    }
    
    var unitsSection: some View {
        Section("Units") {
            Picker("Glucose", selection: $glucosePreference, content: {
                ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                    Text(item.presentableDescription).tag(item)
                })
            })
        }
    }
    
    var timelineSection: some View {
        Section("Timeline") {
            Toggle("Show Prediction", isOn: $timelinePredictionEnabled)
        }
    }
    
    var experimentalSection: some View {
        Section("Experimental Features") {
            if experimentalFeaturesUnlocked || remoteCommands2Enabled {
                Toggle("Remote Commands 2", isOn: $remoteCommands2Enabled)
                Text("Remote commands 2 requires a special Nightscout deploy and Loop version. This will enable command status and other features. See Zulip #caregiver for details")
                    .font(.footnote)
            } else {
                Text("Disabled                             ")
                    .simultaneousGesture(LongPressGesture(minimumDuration: 5.0).onEnded { _ in
                        experimentalFeaturesUnlocked = true
                    })
            }
        }
    }
    
    func looperRowView(looper: Looper) -> some View {
        HStack {
            Button {
                accountService.selectedLooper = looper
            } label: {
                if looper == accountService.selectedLooper {
                    Image(systemName: "circle.fill")
                        .opacity(0.75)
                } else {
                    Image(systemName: "circle")
                        .opacity(0.75)
                }
            }
            .buttonStyle(PlainButtonStyle())
            NavigationLink(value: accountService.createLooperService(looper: looper, settings: settings)) {
                    Text(looper.name)
            }
        }
    }
}
