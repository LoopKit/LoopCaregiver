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
    let looper: Looper
    
    init(looperService: LooperService, looper: Looper){
        self.looperService = looperService
        self.looper = looper
    }
    
    var body: some View {
        VStack {
            HUDView(looperService: looperService, selectedLooper: looper)
            PredicatedGlucoseContainerView(nightscoutDataSource: looper.nightscoutDataSource)
            HStack {
                Text("Nightscout")
                    .bold()
                    .font(.subheadline)
                Spacer()
            }
            .padding(.leading)
            TreatmentGraphScrollView(looper: looper)
            Spacer()
            BottomBarView(looperService: looperService, looper: looper)
        }
    }
}

