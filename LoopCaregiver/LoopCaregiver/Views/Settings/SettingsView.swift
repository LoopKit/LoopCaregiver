//
//  SettingsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var accountService: AccountServiceManager
    @AppStorage(UserDefaults.standard.glucoseUnitKey) var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    @AppStorage(UserDefaults.standard.timelinePredictionEnabledKey) private var timelinePredictionEnabled = false
    @AppStorage(UserDefaults.standard.remoteCommands2EnabledKey) private var remoteCommands2Enabled = false
    
    @ObservedObject var settings: CaregiverSettings
    @Binding var showSheetView: Bool
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            VStack {
                Form {
                    Section("Loopers"){
                        List(accountService.loopers) { looper in
                            NavigationLink(value: accountService.createLooperService(looper: looper, settings: settings)) {
                                Text(looper.name)
                            }
                        }
                        NavigationLink(value: "AddLooper") {
                            HStack {
                                Image(systemName: "plus")
                                    .foregroundColor(.green)
                                Text("Add New Looper")
                            }
                        }
                    }
                    Section("Units") {
                        Picker("Glucose", selection: $glucosePreference, content: {
                            ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                                Text(item.presentableDescription).tag(item)
                            })
                        })
                    }
                    Section("Timeline") {
                        Toggle("Show Prediction", isOn: $timelinePredictionEnabled)
                    }
                    Section("Experimental") {
                        Toggle("Remote Commands 2", isOn: $remoteCommands2Enabled)
                        Text("Remote commands 2 requires a special Nightscout deploy and Loop version. This will enable command status and other features. See Zulip #caregiver for details")
                            .font(.footnote)
                    }
                }
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
}
