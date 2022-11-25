//
//  ContentView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import SwiftUI
import NightscoutClient
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
            HomeView(looperService: accountService.createLooperService(looper: looper), settings: settings)
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
    
    init(looperService: LooperService, settings: CaregiverSettings){
        self.looperService = looperService
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            HUDView(looperService: looperService, settings: looperService.settings)
            PredicatedGlucoseContainerView(remoteDataSource: remoteDataSource, settings: looperService.settings)
            HStack {
                Text("Active Insulin")
                    .bold()
                    .font(.subheadline)
                Spacer()
                Text(formattedIOB())
                    .foregroundColor(.gray)
                    .bold()
                    .font(.subheadline)
            }
            .padding([.leading, .bottom])
            HStack {
                Text("Active Carbohydrates")
                    .bold()
                    .font(.subheadline)
                Spacer()
                Text(formattedCOB())
                    .foregroundColor(.gray)
                    .bold()
                    .font(.subheadline)
            }
            .padding([.leading, .bottom])
            HStack {
                Text("Nightscout")
                    .bold()
                    .font(.subheadline)
                Spacer()
            }
            .padding(.leading)
            TreatmentGraphScrollView(remoteDataSource: remoteDataSource, settings: looperService.settings)
            Spacer()
            BottomBarView(showCarbView: $showCarbView, showBolusView: $showBolusView, showOverrideView: $showOverrideView, showSettingsView: $showSettingsView)
        }
        .ignoresSafeArea(.keyboard) //Avoid keyboard bounce when popping back from sheets
        .sheet(isPresented: $showCarbView) {
            CarbInputView(looperService: looperService, showSheetView: $showCarbView)
        }
        .sheet(isPresented: $showBolusView) {
            BolusInputView(looperService: looperService, showSheetView: $showBolusView)
        }
        .sheet(isPresented: $showOverrideView) {
            OverrideView(looperService: looperService, showSheetView: $showOverrideView)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(accountService: accountService, settings: looperService.settings, showSheetView: $showSettingsView)
        }
    }
    
    func formattedCOB() -> String {
        guard let cob = remoteDataSource.currentCOB?.cob else {
            return ""
        }
        return String(format: "%.0f g", cob)
    }
    
    func formattedIOB() -> String {
        guard let iob = remoteDataSource.currentIOB?.iob else {
            return ""
        }
        return String(format: "%.1f U Total", iob)
    }
    
}

