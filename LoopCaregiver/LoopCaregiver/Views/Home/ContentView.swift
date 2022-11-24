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
    
    @ObservedObject var looperService = LooperService(coreDataService: LooperCoreDataService.shared)
    
    var body: some View {
        if let looper = looperService.selectedLooper {
            HomeView(looperService: looperService, looper: looper)
        } else {
            FirstRunView(looperService: looperService, showSheetView: true)
        }
    }
}

struct FirstRunView: View {
    
    @ObservedObject var looperService: LooperService
    @State var showSheetView: Bool = false
    
    var body: some View {
        SettingsView(looperService: looperService, showSheetView: $showSheetView)
    }
}

struct HomeView: View {
    
    @ObservedObject var looperService: LooperService
    @ObservedObject var nightscoutDataSource: NightscoutDataSource
    
    @State private var showCarbView = false
    @State private var showBolusView = false
    @State private var showOverrideView = false
    @State private var showSettingsView = false
    
    let looper: Looper
    
    init(looperService: LooperService, looper: Looper){
        self.looperService = looperService
        self.nightscoutDataSource = looper.nightscoutDataSource
        self.looper = looper
    }
    
    var body: some View {
        VStack {
            HUDView(looperService: looperService, selectedLooper: looper)
            PredicatedGlucoseContainerView(nightscoutDataSource: looper.nightscoutDataSource)
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
            TreatmentGraphScrollView(looper: looper)
            Spacer()
            BottomBarView(looperService: looperService, looper: looper, showCarbView: $showCarbView, showBolusView: $showBolusView, showOverrideView: $showOverrideView, showSettingsView: $showSettingsView)
        }
        .ignoresSafeArea(.keyboard) //Avoid keyboard bounce when popping back from sheets
        .sheet(isPresented: $showCarbView) {
            CarbInputView(looper: looper, showSheetView: $showCarbView)
        }
        .sheet(isPresented: $showBolusView) {
            BolusInputView(looper: looper, showSheetView: $showBolusView)
        }
        .sheet(isPresented: $showOverrideView) {
            OverrideView(looper: looper, showSheetView: $showOverrideView)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(looperService: looperService, showSheetView: $showSettingsView)
        }
    }
    
    func formattedCOB() -> String {
        guard let cob = looper.nightscoutDataSource.currentCOB?.cob else {
            return ""
        }
        return String(format: "%.0f g", cob)
    }
    
    func formattedIOB() -> String {
        guard let iob = looper.nightscoutDataSource.currentIOB?.iob else {
            return ""
        }
        return String(format: "%.1f U Total", iob)
    }
    
}

