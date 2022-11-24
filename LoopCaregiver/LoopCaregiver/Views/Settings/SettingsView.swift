//
//  SettingsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct SettingsView: View {

    @ObservedObject var accountService: AccountServiceManager
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
                //TODO: This should probably receive a LooperService to have access to these things.
                //We just need to make sure NS data won't be fetched and the Navigationlink things above need adjusted.
                LooperView(accountService: accountService,
                           nightscoutCredentialService: NightscoutCredentialService(credentials: looper.nightscoutCredentials),
                           looper: looper,
                           path: $path)
            }
            .navigationDestination(
                for: String.self
            ) { val in
                LooperSetupView(looperService: accountService, path: $path)
            }
        }
    }
}
