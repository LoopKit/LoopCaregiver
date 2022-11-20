//
//  SettingsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct SettingsView: View {

    @ObservedObject var looperService: LooperService
    @Binding var showSheetView: Bool
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            VStack {
                Form {
                    
                    Section("Loopers"){
                        List(looperService.loopers) { looper in
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
                LooperView(looperService: looperService, looper: looper, path: $path)
            }
            .navigationDestination(
                for: String.self
            ) { val in
                LooperSetupView(looperService: looperService, path: $path)
            }
        }
    }
}
