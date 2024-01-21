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
    
    @ObservedObject var connectivityManager: WatchConnectivityManager
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var looperService: LooperService
    @Environment(\.scenePhase) var scenePhase
    
    init(connectivityManager: WatchConnectivityManager, looperService: LooperService){
        self.connectivityManager = connectivityManager
        self.looperService = looperService
        self.settings = looperService.settings
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            Text(glucoseText())
                .strikethrough(egvIsOutdated())
                .font(.largeTitle)
        }
        .navigationTitle(accountService.selectedLooper?.name ?? "Name?")
        .navigationDestination(for: String.self, destination: { _ in
            SettingsView(connectivityManager: connectivityManager, accountService: accountService, settings: settings)
        })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: "SettingsView") {
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
    
    func glucoseText() -> String {
        remoteDataSource.currentGlucoseSample?.presentableStringValue(displayUnits: settings.glucoseDisplayUnits) ?? " "
    }
    
    func lastGlucoseChange() -> Double? {
        let egvs = remoteDataSource.glucoseSamples
        guard egvs.count > 1 else {
            return nil
        }
        let lastGlucoseValue = egvs[egvs.count - 1].presentableUserValue(displayUnits: settings.glucoseDisplayUnits)
        let priorGlucoseValue = egvs[egvs.count - 2].presentableUserValue(displayUnits: settings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
    
    func egvIsOutdated() -> Bool {
        guard let currentEGV = remoteDataSource.currentGlucoseSample else {
            return true
        }
        return Date().timeIntervalSince(currentEGV.date) > 60 * 10
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

}

#Preview {
    let composer = ServiceComposerPreviews()
    return NavigationStack {
        let looper = composer.accountServiceManager.selectedLooper!
        let looperService = composer.accountServiceManager.createLooperService(looper: looper, settings: composer.settings)
        HomeView(connectivityManager: composer.watchManager, looperService: looperService)
    }
}
