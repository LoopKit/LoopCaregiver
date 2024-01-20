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
    @EnvironmentObject var watchManager: WatchConnectivityManager
    
    @State var path: NavigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            VStack {
                if let looper = accountService.selectedLooper {
                    HomeView(connectivityManager: watchManager, looperService: accountService.createLooperService(looper: looper, settings: settings))
                } else {
                    //Text("No Looper. Open Loop Caregiver on iPhone.")
                    Text("The Caregiver Watch app feature is not complete. Stay tuned.")
                }
            }
            .navigationDestination(for: String.self, destination: { _ in
                SettingsView(connectivityManager: watchManager, accountService: accountService, settings: settings)
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: "SettingsView") {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onChange(of: watchManager.notificationMessage, {
            if let message = watchManager.notificationMessage?.text {
                Task {
                    try await handleDeepLinkURL(message)
                }
            }
        })
    }
    
    @MainActor func handleDeepLinkURL(_ urlString: String) async throws {
        UserDefaults(suiteName: Bundle.main.appGroupSuiteName)?.updateLastPhoneDebugMessage(Date().description)
        guard let url = URL(string: urlString) else {
            return
        }
        
        let deepLink = try DeepLinkParser().parseDeepLink(url: url)
        switch deepLink {
        case .addLooper(let createLooperDeepLink):
            try await handleAddLooperDeepLink(createLooperDeepLink)
        case .selectLooper(let selectLooperDeepLink):
            try await handleSelectLooperDeepLink(selectLooperDeepLink)
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
        .environmentObject(composer.watchManager)
}
