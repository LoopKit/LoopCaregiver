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
    @Environment(\.scenePhase) var scenePhase
    @State var navigationPath: NavigationPath
    
    init(looperService: LooperService, navigationPath: NavigationPath){
        self.looperService = looperService
        self.settings = looperService.settings
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
        _navigationPath = State(initialValue: navigationPath)
    }
    
    var body: some View {
        VStack {
            Text(glucoseText())
                .strikethrough(egvIsOutdated())
                .font(.largeTitle)
        }
        .navigationTitle(accountService.selectedLooper?.name ?? "Name?")
        .navigationDestination(for: String.self, destination: { _ in
            SettingsView(settings: settings)
        })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: "SettingsView") {
                    Image(systemName: "gear")
                }            }
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
    
    func glucoseText() -> String {
        remoteDataSource.currentGlucoseSample?.presentableStringValue(displayUnits: settings.glucoseDisplayUnits) ?? " "
    }
    
    func egvIsOutdated() -> Bool {
        guard let currentEGV = remoteDataSource.currentGlucoseSample else {
            return true
        }
        return Date().timeIntervalSince(currentEGV.date) > 60 * 10
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "LoopCaregiverWatchAppExtension")
    }
}
