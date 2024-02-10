//
//  HomeView.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 12/18/23.
//

import LoopCaregiverKit
import LoopCaregiverKitUI
import SwiftUI
import WidgetKit
    
struct HomeView: View {
    
    @ObservedObject var connectivityManager: WatchSession
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var looperService: LooperService
    @Environment(\.scenePhase) var scenePhase
    
    init(connectivityManager: WatchSession, looperService: LooperService){
        self.connectivityManager = connectivityManager
        self.looperService = looperService
        self.settings = looperService.settings
        self.accountService = looperService.accountService
        self.remoteDataSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(remoteDataSource.currentGlucoseSample?.presentableStringValue(displayUnits: settings.glucoseDisplayUnits) ?? " ")
                    .strikethrough(egvIsOutdated())
                    .font(.largeTitle)
                    .foregroundColor(egvValueColor())
                if let egv = remoteDataSource.currentGlucoseSample {
                    Image(systemName: egv.arrowImageName())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15.0)
                        .foregroundColor(egvValueColor())
                }
                VStack {
                    Text(lastEGVTimeFormatted())
                        .font(.footnote)
                        .if(egvIsOutdated(), transform: { view in
                            view.foregroundColor(.red)
                        })
                            Text(lastEGVDeltaFormatted())
                            .font(.footnote)
                }
            }
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
                await remoteDataSource.updateData()
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
    
    func lastEGVTimeFormatted() -> String {
        guard let currentEGV = remoteDataSource.currentGlucoseSample else {
            return ""
        }
        
        return currentEGV.date.formatted(.dateTime.hour().minute())
    }
    
    func egvIsOutdated() -> Bool {
        guard let currentEGV = remoteDataSource.currentGlucoseSample else {
            return true
        }
        return Date().timeIntervalSince(currentEGV.date) > 60 * 10
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = remoteDataSource.currentGlucoseSample {
            return ColorType(quantity: currentEGV.quantity).color
        } else {
            return .white
        }
    }
    
    func lastEGVDeltaFormatted() -> String {
        
        guard let lastEGVChange = self.lastGlucoseChange() else {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.positivePrefix = "+"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        
        guard let formattedEGV = formatter.string(from: lastEGVChange as NSNumber) else {
            return ""
        }
        
        return formattedEGV
        
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
        HomeView(connectivityManager: composer.watchSession, looperService: looperService)
    }
}
