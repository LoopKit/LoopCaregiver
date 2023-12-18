//
//  HomeView.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 12/18/23.
//

import LoopCaregiverKit
import SwiftUI
import WidgetKit
    
struct HomeView: View {
    
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var looperService: LooperService
    @State var showDiagnostics: Bool = false
    @Environment(\.scenePhase) var scenePhase
    
    init(looperService: LooperService){
        self.looperService = looperService
        self.settings = looperService.settings
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            Text(remoteDataSource.glucoseSamples.last?.quantity.debugDescription ?? "None")
            Text(accountService.selectedLooper?.name ?? "Name?")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showDiagnostics = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await looperService.remoteDataSource.updateData()
                        reloadWidget()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            Task {
                await looperService.remoteDataSource.updateData()
            }
        })
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "LoopCaregiverWatchAppExtension")
    }
}
