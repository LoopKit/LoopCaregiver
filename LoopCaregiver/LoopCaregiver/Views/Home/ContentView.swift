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
    
    init(){
        self.accountService = AccountServiceManager(accountService: CoreDataAccountService(inMemory: false))
    }
    
    var body: some View {
        if let looper = accountService.selectedLooper {
            HomeView(looperService: LooperService(looper: looper,
                                                  accountService: accountService,
                                                  remoteDataSource: RemoteDataServiceManager(remoteDataProvider: NightscoutDataSource(looper: looper))))
        } else {
            FirstRunView(accountService: accountService, showSheetView: true)
        }
    }
}

struct FirstRunView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @State var showSheetView: Bool = false
    
    var body: some View {
        SettingsView(accountService: accountService, showSheetView: $showSheetView)
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
            HUDView(looperService: looperService)
            PredicatedGlucoseContainerView(remoteDataSource: remoteDataSource)
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
            TreatmentGraphScrollView(remoteDataSource: remoteDataSource)
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
            SettingsView(accountService: accountService, showSheetView: $showSettingsView)
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

