//
//  HUDView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import Combine
import LoopCaregiverKit
import LoopCaregiverKitUI
import HealthKit
import LoopKit
import SwiftUI

struct HUDView: View {
    
    @ObservedObject var hudViewModel: HUDViewModel
    @ObservedObject var nightscoutDataSource: RemoteDataServiceManager
    @ObservedObject private var settings: CaregiverSettings
    @State private var looperPopoverShowing: Bool = false
    
    init(looperService: LooperService, settings: CaregiverSettings){
        self.hudViewModel = HUDViewModel(selectedLooper: looperService.looper, accountService: looperService.accountService, settings: settings)
        self.nightscoutDataSource = looperService.remoteDataSource
        self.settings = settings
    }
    
    var body: some View {
        VStack {
            HStack (alignment: .center) {
                HStack {
                    Text(nightscoutDataSource.currentGlucoseSample?.presentableStringValue(displayUnits: settings.glucoseDisplayUnits) ?? " ")
                        .strikethrough(egvIsOutdated())
                        .font(.largeTitle)
                        .foregroundColor(egvValueColor())
                    if let egv = nightscoutDataSource.currentGlucoseSample {
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
                Spacer()
                HStack {
                    if nightscoutDataSource.updating {
                        ProgressView()
                            .padding([.trailing], 10.0)
                    }
                    pickerButton
                }
            }.onChange(of: hudViewModel.selectedLooper) { newValue in
                looperPopoverShowing = false
            }
            if let (activeOverride, status) = nightscoutDataSource.activeOverrideAndStatus() {
                HStack {
                    Text(activeOverride.presentableDescription())
                        .bold()
                        .font(.subheadline)
                    Spacer()
                    if let endTimeDescription = status.endTimeDescription() {
                        Text(endTimeDescription)
                            .foregroundColor(.gray)
                            .bold()
                            .font(.subheadline)
                    }
                }

            }
        }
    }
    
   var pickerButton: some View {
        Button {
            looperPopoverShowing = true
        } label: {
            HStack {
                Text(hudViewModel.selectedLooper.name)
                Image(systemName: "person.crop.circle")
            }
        }
        .popover(isPresented: $looperPopoverShowing) {
            NavigationStack {
                Form {
                    Picker("", selection: $hudViewModel.selectedLooper) {
                        ForEach(hudViewModel.loopers()) { looper in
                            Text(looper.name).tag(looper)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .toolbar(content: {
                    ToolbarItem {
                        Button {
                            looperPopoverShowing = false
                        } label: {
                            Text("Done")
                        }
                    }
                })
            }
            .presentationDetents([.medium])
        }
    }
    
    func lastGlucoseChange() -> Double? {
        let egvs = nightscoutDataSource.glucoseSamples
        guard egvs.count > 1 else {
            return nil
        }
        let lastGlucoseValue = egvs[egvs.count - 1].presentableUserValue(displayUnits: settings.glucoseDisplayUnits)
        let priorGlucoseValue = egvs[egvs.count - 2].presentableUserValue(displayUnits: settings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = nightscoutDataSource.currentGlucoseSample {
            return ColorType(quantity: currentEGV.quantity).color
        } else {
            return .white
        }
    }
    
    func egvIsOutdated() -> Bool {
        guard let currentEGV = nightscoutDataSource.currentGlucoseSample else {
            return true
        }
        return Date().timeIntervalSince(currentEGV.date) > 60 * 10
    }
    
    func lastEGVTimeFormatted() -> String {
        guard let currentEGV = self.nightscoutDataSource.currentGlucoseSample else {
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
}

class HUDViewModel: ObservableObject {
    
    @Published var glucoseDisplayUnits: HKUnit
    /*
     TODO: This property both reflects
     the selectedLooper account to the AccountServiceManager
     and the selection state of the HUD view. This may be a problem
     as it can lead to recursive updates since updating the active
     loop user, updates the lastSelectedDate, which sends a new
     selectedLooper to the initializer of this view.
     See note == method of Looper.
     See also the refresh() method of AccountServiceManager which
     may be working around some of this.
     */
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
        
        //TODO: This is the only things allowing updates like this to work: accountService.selectedLooper = looper
        //This logic should be in the accountService
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
