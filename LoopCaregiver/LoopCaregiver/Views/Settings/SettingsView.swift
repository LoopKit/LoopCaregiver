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
    
    @ObservedObject var settings: CaregiverSettings
    @Binding var showSheetView: Bool
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            VStack {
                Form {
                    Section("Loopers"){
                        List(accountService.loopers) { looper in
                            NavigationLink(value: looper) {
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
                }
            }
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.showSheetView = false
            }) {
                Text("Done").bold()
            })
            .navigationDestination(
                for: Looper.self
            ) { looper in
                LooperView(looperService: accountService.createLooperService(looper: looper, settings: settings),
                           nightscoutCredentialService: NightscoutCredentialService(credentials: looper.nightscoutCredentials),
                           looper: looper,
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
