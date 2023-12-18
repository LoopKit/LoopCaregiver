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
    
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @ObservedObject var accountService: AccountServiceManager
    @State var showDiagnostics: Bool = false
    let settings: CaregiverSettings
    
    init(){
        let composer = ServiceComposer()
        self.settings = composer.settings
        self.accountService = composer.accountServiceManager
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let looper = accountService.selectedLooper {
                    HomeView(looperService: accountService.createLooperService(looper: looper, settings: settings))
                } else {
                    //Text("No Looper. Open Loop Caregiver on iPhone.")
                    Text("The Caregiver Watch app feature is not complete. Stay tuned.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("?") {
                        showDiagnostics = true
                    }
                }
            }
        }
        .sheet(isPresented: $showDiagnostics, content: {
            DiagnosticView()
        })
        .onChange(of: connectivityManager.notificationMessage, {
            if let message = connectivityManager.notificationMessage?.text {
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
        WidgetCenter.shared.reloadTimelines(ofKind: "LoopCaregiverWatchAppExtension")
    }
}

#Preview {
    ContentView()
}
