//
//  ContentView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import SwiftUI
import Charts
import CoreData
import LoopKit

struct ContentView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    let settings: CaregiverSettings = CaregiverSettings()
    
    init(){
        self.accountService = AccountServiceManager(accountService: CoreDataAccountService(inMemory: false))
    }
    
    var body: some View {
        if let looper = accountService.selectedLooper {
            HomeView(looperService: accountService.createLooperService(looper: looper, settings: settings))
        } else {
            FirstRunView(accountService: accountService, settings: settings, showSheetView: true)
        }
    }
}

struct FirstRunView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    let settings: CaregiverSettings
    @State var showSheetView: Bool = false
    
    var body: some View {
        SettingsView(accountService: accountService, settings: settings, showSheetView: $showSheetView)
    }
}

struct HomeView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    let looperService: LooperService
    
    @State private var showCarbView = false
    @State private var showBolusView = false
    @State private var showOverrideView = false
    @State private var showSettingsView = false
    
    init(looperService: LooperService){
        self.looperService = looperService
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            HUDView(looperService: looperService, settings: looperService.settings)
                .padding([.leading, .trailing])
            if let recommendedBolus = remoteDataSource.recommendedBolus {
                TitleSubtitleRowView(title: "Recommended Bolus", subtitle: LocalizationUtils.presentableStringFromBolusAmount(recommendedBolus) + " U")
                    .padding([.leading, .trailing, .bottom])
            }
            ChartsListView(looperService: looperService, remoteDataSource: remoteDataSource, settings: looperService.settings)
                .padding([.leading, .trailing, .bottom])
            Spacer()    
            BottomBarView(showCarbView: $showCarbView, showBolusView: $showBolusView, showOverrideView: $showOverrideView, showSettingsView: $showSettingsView)
        }
        .ignoresSafeArea(.keyboard) //Avoid keyboard bounce when popping back from sheets
        .sheet(isPresented: $showCarbView) {
            CarbInputView(looperService: looperService, showSheetView: $showCarbView)
        }
        .sheet(isPresented: $showBolusView) {
            BolusInputView(looperService: looperService, remoteDataSource: looperService.remoteDataSource, showSheetView: $showBolusView)
        }
        .sheet(isPresented: $showOverrideView) {
            OverrideView(looperService: looperService, showSheetView: $showOverrideView)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(accountService: accountService, settings: looperService.settings, showSheetView: $showSettingsView)
        }
    }
}

