//
//  HomeView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/20/24.
//

import Foundation
import LoopCaregiverKit
import SwiftUI
import WidgetKit

struct HomeView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var looperService: LooperService
    var watchSession: WatchSession
    
    @State private var showCarbView = false
    @State private var showBolusView = false
    @State private var showOverrideView = false
    @State private var showSettingsView = false
    
    @Environment(\.scenePhase) var scenePhase
    
    init(looperService: LooperService, watchSession: WatchSession){
        self.looperService = looperService
        self.settings = looperService.settings
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
        self.watchSession = watchSession
    }
    
    var body: some View {
        VStack {
            HUDView(looperService: looperService, settings: looperService.settings)
                .padding([.leading, .trailing])
                .padding([.bottom], 5.0)
                .background(Color.cellBackgroundColor)
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
            SettingsView(looperService: looperService, accountService: accountService, settings: looperService.settings, watchSession: watchSession, showSheetView: $showSettingsView)
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


#Preview {
    let composer = ServiceComposerPreviews()
    let looper = composer.accountServiceManager.selectedLooper!
    var showSheetView = true
    let showSheetBinding = Binding<Bool>(get: {showSheetView}, set: {showSheetView = $0})
    let looperService = composer.accountServiceManager.createLooperService(looper: looper, settings: composer.settings)
    return HomeView(looperService: looperService, watchSession: composer.watchSession)
}
