//
//  ContentView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import LoopCaregiverKit
import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var accountService: AccountServiceManager
    @EnvironmentObject var settings: CaregiverSettings
    @EnvironmentObject var watchSession: WatchSession
    
    @State var deepLinkErrorShowing = false
    @State var deepLinkErrorText: String = ""
    
    var body: some View {
        return Group {
            if let looper = accountService.selectedLooper {
                HomeView(looperService: accountService.createLooperService(looper: looper, settings: settings), watchSession: watchSession)
            } else {
                FirstRunView(accountService: accountService, settings: settings, showSheetView: true)
            }
        }.onOpenURL(perform: { (url) in
            Task {
                do {
                    try await handleDeepLinkURL(url)
                } catch {
                    deepLinkErrorShowing = true
                    deepLinkErrorText = error.localizedDescription
                }
            }
        })
        .alert(deepLinkErrorText, isPresented: $deepLinkErrorShowing) {
            Button(role: .cancel) {
            } label: {
                Text("OK")
            }
        }
        .background(AppExpirationAlerterRepresentable())
        
        @MainActor func handleDeepLinkURL(_ url: URL) async throws {
            
            let deepLink = try DeepLinkParser().parseDeepLink(url: url)
            switch deepLink {
            case .addLooper(let createLooperDeepLink):
                try await handleAddLooperDeepLink(createLooperDeepLink)
            case .selectLooper(let selectLooperDeepLink):
                try await handleSelectLooperDeepLink(selectLooperDeepLink)
            }
        }
        
        @MainActor
        func handleSelectLooperDeepLink(_ deepLink: SelectLooperDeepLink) async throws {
            guard let looper = accountService.loopers.first(where: {$0.id == deepLink.looperUUID}) else {
                return
            }
            
            if accountService.selectedLooper != looper {
                accountService.selectedLooper = looper
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
        }
    }
}
