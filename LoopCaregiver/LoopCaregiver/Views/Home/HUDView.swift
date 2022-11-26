//
//  HUDView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import SwiftUI
import NightscoutClient
import Combine
import LoopKit
import HealthKit

struct HUDView: View {
    
    @ObservedObject var hudViewModel: HUDViewModel
    @ObservedObject var nightscoutDateSource: RemoteDataServiceManager
    @ObservedObject private var settings: CaregiverSettings
    
    init(looperService: LooperService, settings: CaregiverSettings){
        self.hudViewModel = HUDViewModel(selectedLooper: looperService.looper, accountService: looperService.accountService, settings: settings)
        self.nightscoutDateSource = looperService.remoteDataSource
        self.settings = settings
    }
    
    var body: some View {
        VStack {
            HStack (alignment: .center) {
                Text(nightscoutDateSource.currentGlucoseSample?.presentableStringValue(displayUnits: settings.glucoseDisplayUnits) ?? " ")
                    .font(.largeTitle)
                    .foregroundColor(egvValueColor())
                if let egv = nightscoutDateSource.currentGlucoseSample {
                    Image(systemName: arrowImageName(egv: egv))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20.0)
                        .foregroundColor(egvValueColor())
                }
                VStack {
                    Text(lastEGVTimeFormatted())
                        .font(.footnote)
                    Text(lastEGVDeltaFormatted())
                        .font(.footnote)
                }
                Spacer()
                if nightscoutDateSource.updating {
                    ProgressView()
                }
                Picker("Looper", selection: $hudViewModel.selectedLooper) {
                    ForEach(hudViewModel.loopers()) { looper in
                        Text(looper.name).tag(looper)
                    }
                }
            }

        }
    }
    
    func arrowImageName(egv: NewGlucoseSample) -> String {
    
        guard let trendRate = egv.trendRate else {
            return "questionmark"
        }
        
        guard let trend = EGVTrend(rawValue: Int(trendRate.doubleValue(for: .milligramsPerDeciliter))) else { //TODO: Could crash on large values
            return "questionmark"
        }
        
        switch trend {
            
        case .doubleUp:
            return "arrow.up"
        case .singleUp:
            return  "arrow.up"
        case .fortyFiveUp:
            return  "arrow.up.forward"
        case .flat:
            return  "arrow.right"
        case .fortyFiveDown:
            return  "arrow.down.forward"
        case .singleDown:
            return  "arrow.down"
        case .doubleDown:
            return  "arrow.down"
        case .nonComputable:
            return  "questionmark"
        case .outOfRange:
            return  "questionmark"
        }
    }
    
    func lastGlucoseChange() -> Double? {
        let egvs = nightscoutDateSource.glucoseSamples
        guard egvs.count > 1 else {
            return nil
        }
        let lastGlucoseValue = egvs[egvs.count - 1].presentableUserValue(displayUnits: settings.glucoseDisplayUnits)
        let priorGlucoseValue = egvs[egvs.count - 2].presentableUserValue(displayUnits: settings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = nightscoutDateSource.currentGlucoseSample {
            return ColorType(quantity: currentEGV.quantity).color
        } else {
            return .white
        }
    }
    
    func lastEGVTimeFormatted() -> String {
        guard let currentEGV = self.nightscoutDateSource.currentGlucoseSample else {
            return ""
        }
        
        return currentEGV.date.formatted(.dateTime.hour().minute())
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
    
    enum EGVTrend: Int {
        case doubleUp = 1
        case singleUp = 2
        case fortyFiveUp = 3
        case flat = 4
        case fortyFiveDown = 5
        case singleDown = 6
        case doubleDown = 7
        case nonComputable = 8
        case outOfRange = 9
    }
    
    func arrowForTrend(rawValue: Int?) -> String {
        guard let rawValue, let egvTrend = EGVTrend(rawValue: rawValue) else {
            return "?"
        }
        
        switch egvTrend {
        case .doubleUp:
            return ""
        default:
            return ""
        }
    }
}

class HUDViewModel: ObservableObject {
    
    @Published var glucoseDisplayUnits: HKUnit
    @Published var selectedLooper: Looper {
        didSet {
            do {
                try accountService.updateActiveLoopUser(selectedLooper)
            } catch {
                print(error)
            }
        }
    }
    @ObservedObject var accountService: AccountServiceManager
    private var settings: CaregiverSettings
    private var subscribers: Set<AnyCancellable> = []
    
    init(selectedLooper: Looper, accountService: AccountServiceManager, settings: CaregiverSettings) {
        self.selectedLooper = selectedLooper
        self.accountService = accountService
        self.settings = settings
        self.glucoseDisplayUnits = self.settings.glucoseDisplayUnits
        
        self.accountService.$selectedLooper.sink { val in
        } receiveValue: { [weak self] updatedUser in
            if let self, let updatedUser, self.selectedLooper != updatedUser {
                self.selectedLooper = updatedUser
            }
        }.store(in: &subscribers)
    }
    
    func loopers() -> [Looper] {
        return accountService.loopers
    }
    
    @objc func defaultsChanged(notication: Notification){
        if self.glucoseDisplayUnits != settings.glucoseDisplayUnits {
            self.glucoseDisplayUnits = settings.glucoseDisplayUnits
        }
    }
}
