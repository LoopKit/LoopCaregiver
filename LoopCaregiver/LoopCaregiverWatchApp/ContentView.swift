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
                    Text("Open Caregiver Settings on your iPhone and tap 'Setup Watch'")
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
                    try await handleDeepLinkURL(url)
                } catch {
                    print("Error handling deep link: \(error)")
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
    
    @MainActor func handleDeepLinkURL(_ url: URL) async throws {
        let deepLink = try DeepLinkParser().parseDeepLink(url: url)
        switch deepLink {
        case .addLooper(let createLooperDeepLink):
            try await handleAddLooperDeepLink(createLooperDeepLink)
        case .selectLooper(let selectLooperDeepLink):
            try await handleSelectLooperDeepLink(selectLooperDeepLink)
        case .requestWatchConfigurationDeepLink:
            assert(false, "Should not be received from iPhone")
        }
    }
    
    @MainActor
    func handleAddLooperDeepLink(_ deepLink: CreateLooperDeepLink) async throws {
        let looper = Looper(identifier: UUID(), name: deepLink.name, nightscoutCredentials: NightscoutCredentials(url: deepLink.nsURL, secretKey: deepLink.secretKey, otpURL: deepLink.otpURL.absoluteString), lastSelectedDate: Date())
        let service = accountService.createLooperService(looper: looper, settings: settings)
        try await service.remoteDataSource.checkAuth()

        if let existingLooper = accountService.loopers.first(where: {$0.name == looper.name}) {
            try accountService.removeLooper(existingLooper)
        }
        try accountService.addLooper(looper)
        try accountService.updateActiveLoopUser(looper)
        
        reloadWidget()
    }
    
    @MainActor
    func handleSelectLooperDeepLink(_ deepLink: SelectLooperDeepLink) async throws {
        guard let looper = accountService.loopers.first(where: {$0.id == deepLink.looperUUID}) else {
            deepLinkErrorShowing = true
            if accountService.loopers.isEmpty {
                // This could send a request to phone to send Loopers
                deepLinkErrorText = "No Loopers available on Watch. Open Caregiver Settings on your iPhone and tap 'Setup Watch'. Then remove this complication from your Watch face and add it again."
                do {
                    try watchService.requestWatchConfiguration()
                } catch {
                    print(error)
                }
            } else {
                deepLinkErrorText = "The selected complication is invalid. You must remove it from your Apple Watch face and add it again."
            }

            return
        }
        
        if accountService.selectedLooper != looper {
            accountService.selectedLooper = looper
        }
        
        reloadWidget()
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    let composer = ServiceComposerPreviews()
    return ContentView()
        .environmentObject(composer.accountServiceManager)
        .environmentObject(composer.settings)
        .environmentObject(composer.watchService)
}
