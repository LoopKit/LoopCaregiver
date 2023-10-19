//
//  ContentView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @State var deepLinkErrorShowing = false
    @State var deepLinkErrorText: String = ""
    let settings: CaregiverSettings
    
    init(){
        let composer = ServiceComposer()
        self.settings = composer.settings
        self.accountService = composer.accountServiceManager
    }
    
    var body: some View {
        return Group {
            if let looper = accountService.selectedLooper {
                HomeView(looperService: accountService.createLooperService(looper: looper, settings: settings))
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

struct FirstRunView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    let settings: CaregiverSettings
    @State var showSheetView: Bool = false
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            LooperSetupView(accountService: accountService, settings: settings, path: $path)
        }
    }
}

struct HomeView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var looperService: LooperService
    
    @State private var showCarbView = false
    @State private var showBolusView = false
    @State private var showOverrideView = false
    @State private var showSettingsView = false
    
    @Environment(\.scenePhase) var scenePhase
    
    init(looperService: LooperService){
        self.looperService = looperService
        self.settings = looperService.settings
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            HUDView(looperService: looperService, settings: looperService.settings)
                .padding([.leading, .trailing])
            if let recommendedBolus = remoteDataSource.recommendedBolus {
                TitleSubtitleRowView(title: "Recommended Bolus", subtitle: LocalizationUtils.presentableStringFromBolusAmount(recommendedBolus) + " U")
                    .padding([.bottom, .trailing], 5.0)
            }
            ChartsListView(looperService: looperService, remoteDataSource: remoteDataSource, settings: looperService.settings)
                .padding([.leading, .trailing], 5.0)
            BottomBarView(showCarbView: $showCarbView, showBolusView: $showBolusView, showOverrideView: $showOverrideView, showSettingsView: $showSettingsView, remoteDataSource: remoteDataSource)
        }
        .overlay {
            if !disclaimerValid(){
                disclaimerOverlay()
            }
        }
        .ignoresSafeArea(.keyboard) //Avoid keyboard bounce when popping back from sheets
        .sheet(isPresented: $showCarbView) {
            CarbInputView(looperService: looperService, showSheetView: $showCarbView)
        }
        .sheet(isPresented: $showBolusView) {
            BolusInputView(looperService: looperService, remoteDataSource: looperService.remoteDataSource, showSheetView: $showBolusView)
        }
        .sheet(isPresented: $showOverrideView) {
            NavigationStack {
                OverrideView(delegate: looperService.remoteDataSource) {
                    showOverrideView = false
                }
                .navigationBarTitle(Text("Custom Preset"), displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    showOverrideView = false
                }) {
                    Text("Cancel")
                })
            }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(looperService: looperService, accountService: accountService, settings: looperService.settings, showSheetView: $showSettingsView)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    func disclaimerOverlay() -> some View {
        return ZStack {
            Color.cellBackgroundColor
            DisclaimerView(disclaimerAgreedTo: {
                settings.disclaimerAcceptedDate = Date()
            })
        }
    }
    
    func disclaimerValid() -> Bool {
        guard let disclaimerAcceptedDate = settings.disclaimerAcceptedDate else {
            return false
        }
        
        return disclaimerAcceptedDate > Date().addingTimeInterval(-60*60*24*365)
    }
}

