//
//  ContentView.swift
//  LoopCaregiverWatchApp Watch App
//
//  Created by Bill Gestrich on 10/27/23.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    var userDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)!
    @State var lastPhoneDebugMessage: String? = nil
    
    var body: some View {
        VStack {
            if let lastMessage = lastPhoneDebugMessage {
                Button(action: {
                    reloadWidget()
                }, label: {
                    Text("Reload Widget")
                })
                Text(lastMessage)
            } else {
                Text("The Caregiver Watch app feature is not complete. Stay tuned.")
            }
        }
        .padding()
        .onChange(of: connectivityManager.notificationMessage, {
            if let message = connectivityManager.notificationMessage?.text {
                userDefaults.updateLastPhoneDebugMessage(message)
                lastPhoneDebugMessage = message
            }
        })
        .onAppear {
            self.lastPhoneDebugMessage = userDefaults.lastPhoneDebugMessage
        }
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "LoopCaregiverWatchAppExtension")
    }
}

#Preview {
    ContentView()
}
