//
//  ContentView.swift
//  LoopCaregiverWatchApp Watch App
//
//  Created by Bill Gestrich on 10/27/23.
//

import Foundation
import LoopCaregiverKit
import SwiftUI
import WidgetKit

struct ContentView: View {
    
    @EnvironmentObject var accountService: AccountServiceManager
    var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject var settings: CaregiverSettings
    @EnvironmentObject var watchService: WatchService
    
    @State var deepLinkErrorShowing = false
    @State var deepLinkErrorText: String = ""
    
    @State var path: NavigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            VStack {
                if let looper = accountService.selectedLooper {
                    HomeView(connectivityManager: watchService, looperService: accountService.createLooperService(looper: looper, settings: settings))
                } else {
                    Text("The Caregiver Watch app feature is not complete. Stay tuned.")
                    //Text("Open Caregiver Settings on your iPhone and tap 'Setup Watch'")
                }
            }
            .navigationDestination(for: String.self, destination: { _ in
                SettingsView(connectivityManager: watchService, accountService: accountService, settings: settings)
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: "SettingsView") {
                        Image(systemName: "gear")
                    }
                }
            }
            .alert(deepLinkErrorText, isPresented: $deepLinkErrorShowing) {
                Button(role: .cancel) {
                } label: {
                    Text("OK")
                }
            }
        }
        .onChange(of: watchService.receivedWatchConfiguration, {
            if let receivedWatchConfiguration = watchService.receivedWatchConfiguration {
                Task {
                    await updateWatchConfiguration(watchConfiguration: receivedWatchConfiguration)
                }
            }
        })
        .onOpenURL(perform: { (url) in
            Task {
                do {
                    try await deepLinkHandler.handleDeepLinkURL(url)
                    reloadWidget()
                } catch {
                    print("Error handling deep link: \(error)")
                    deepLinkErrorText = error.localizedDescription
                    deepLinkErrorShowing = true
                }
            }
        })
        .onAppear {
            if accountService.selectedLooper == nil {
                do {
                    try watchService.requestWatchConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    @MainActor func updateWatchConfiguration(watchConfiguration: WatchConfiguration) async {
        
        let existingLoopers = accountService.loopers
        
        var removedLoopers = [Looper]()
        for existingLooper in existingLoopers {
            if !watchConfiguration.loopers.contains(where: { $0.id == existingLooper.id }) {
                removedLoopers.append(existingLooper)
            }
        }
        for looper in removedLoopers {
            try? accountService.removeLooper(looper)
        }
        
        var addedLoopers = [Looper]()
        for configurationLooper in watchConfiguration.loopers {
            if !existingLoopers.contains(where: { $0.id == configurationLooper.id }) {
                addedLoopers.append(configurationLooper)
            }
        }
        
        for looper in addedLoopers {
            try? accountService.addLooper(looper)
        }
        
        //To ensure new Loopers show in widget recommended configurations.
        WidgetCenter.shared.invalidateConfigurationRecommendations()
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    let composer = ServiceComposerPreviews()
    return ContentView(deepLinkHandler: composer.deepLinkHandler)
        .environmentObject(composer.accountServiceManager)
        .environmentObject(composer.settings)
        .environmentObject(composer.watchService)
}
