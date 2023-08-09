//
//  RemoteDataServiceManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation
import LoopKit
import NightscoutKit
import HealthKit
import UIKit //For willEnterForegroundNotification

class RemoteDataServiceManager: ObservableObject, RemoteDataServiceProvider {

    @Published var currentGlucoseSample: NewGlucoseSample? = nil
    @Published var glucoseSamples: [NewGlucoseSample] = []
    @Published var predictedGlucose: [NewGlucoseSample] = []
    @Published var carbEntries: [CarbCorrectionNightscoutTreatment] = []
    @Published var bolusEntries: [BolusNightscoutTreatment] = []
    @Published var basalEntries: [TempBasalNightscoutTreatment] = []
    @Published var overrideEntries: [OverrideTreatment] = []
    @Published var latestDeviceStatus: DeviceStatus? = nil
    @Published var recommendedBolus: Double? = nil
    @Published var currentIOB: IOBStatus? = nil
    @Published var currentCOB: COBStatus? = nil
    @Published var currentProfile: ProfileSet?
    @Published var recentCommands: [RemoteCommand] = []
    @Published var updating: Bool = false
    
    private let remoteDataProvider: RemoteDataServiceProvider
    private var dateUpdateTimer: Timer?
    
    init(remoteDataProvider: RemoteDataServiceProvider){
        self.remoteDataProvider = remoteDataProvider
        
        Task {
            await self.updateData()
        }
        
        monitorForUpdates(updateInterval: 30)
    }
    
    func monitorForUpdates(updateInterval: TimeInterval) {
        self.dateUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true, block: { [weak self] timer in
            guard let self else { return }
            Task {
                await self.updateData()
            }
        })
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.updateData()
            }
        }
    }
    
    @MainActor
    func updateData() async {
        
        updating = true
        
        do {
            let glucoseSamplesAsync = try await remoteDataProvider.fetchGlucoseSamples()
                .sorted(by: {$0.date < $1.date})
                
            if glucoseSamplesAsync != self.glucoseSamples {
                self.glucoseSamples = glucoseSamplesAsync
            }
            
            if let latestGlucoseSample = glucoseSamplesAsync.filter({$0.date <= nowDate()}).last, latestGlucoseSample != currentGlucoseSample {
                currentGlucoseSample = latestGlucoseSample
            }
            
            async let carbEntriesAsync = remoteDataProvider.fetchCarbEntries()
            async let bolusEntriesAsync = remoteDataProvider.fetchBolusEntries()
            async let basalEntriesAsync = remoteDataProvider.fetchBasalEntries()
            async let overrideEntriesAsync = remoteDataProvider.fetchOverrideEntries()
            async let deviceStatusAsync = remoteDataProvider.fetchLatestDeviceStatus()
            async let recentCommandsAsync = remoteDataProvider.fetchRecentCommands()
            async let curentProfileAsync = remoteDataProvider.fetchCurrentProfile()
            
            let carbEntries = try await carbEntriesAsync
            if carbEntries != self.carbEntries {
                self.carbEntries = carbEntries
            }
            
            let bolusEntries = try await bolusEntriesAsync
            if bolusEntries != self.bolusEntries {
                self.bolusEntries = bolusEntries
            }
            
            let basalEntries = try await basalEntriesAsync
            if basalEntries != self.basalEntries {
                self.basalEntries = basalEntries
            }
            
            let overrideEntries = try await overrideEntriesAsync
            if overrideEntries != self.overrideEntries {
                self.overrideEntries = overrideEntries
            }
            
            if let deviceStatus = try await deviceStatusAsync {
                
                if latestDeviceStatus?.timestamp != deviceStatus.timestamp {
                    self.latestDeviceStatus = deviceStatus
                }
                
                if let iob = deviceStatus.loopStatus?.iob,
                   iob != self.currentIOB {
                    self.currentIOB = iob
                }
                
                if let cob = deviceStatus.loopStatus?.cob,
                   cob != self.currentCOB {
                    self.currentCOB = cob
                }
                
                let predictedGlucoseSamples = predictedGlucoseSamples(latestDeviceStatus: deviceStatus)
                if predictedGlucoseSamples != self.predictedGlucose {
                    self.predictedGlucose = predictedGlucoseSamples
                }
            }
            
            let recentCommands = try await recentCommandsAsync
            if recentCommands != self.recentCommands {
                self.recentCommands = recentCommands
            }
            
            let currentProfile = try await curentProfileAsync
            if currentProfile != self.currentProfile {
                self.currentProfile = currentProfile
            }
            
        } catch {
            
        }
        
        updating = false
        self.refreshCalculatedData()
    }
    
    @MainActor
    func refreshCalculatedData() {
        guard let updatedRecomendedBolus = calculateValidRecommendedBolus() else {
            self.recommendedBolus = nil
            return
        }
        
        guard self.recommendedBolus != updatedRecomendedBolus else {
            return
        }
        
        self.recommendedBolus = updatedRecomendedBolus
    }
  
    func calculateValidRecommendedBolus() -> Double? {
        guard let latestDeviceStatus = self.latestDeviceStatus else {
            return nil
        }
        
        guard let recommendedBolus = latestDeviceStatus.loopStatus?.recommendedBolus else {
            return nil
        }
        
        guard recommendedBolus > 0.0 else {
            return nil
        }
        
        let expired = Date().timeIntervalSince(latestDeviceStatus.timestamp) > 60 * 7
        guard !expired  else {
            return nil
        }
        
        if let latestBolusEntry = bolusEntries.filter({$0.timestamp < nowDate()}).sorted(by: {$0.timestamp < $1.timestamp}).last {
            if latestBolusEntry.timestamp >= latestDeviceStatus.timestamp {
                //Reject recommended bolus if a bolus occurred afterward.
                return nil
            }
        }
        
        return recommendedBolus
    }
    
    func predictedGlucoseSamples(latestDeviceStatus: DeviceStatus) -> [NewGlucoseSample] {
        guard let loopPrediction = latestDeviceStatus.loopStatus?.predicted else {
            return []
        }
        
        let predictedValues = loopPrediction.values
        
        var predictedSamples = [NewGlucoseSample]()
        var currDate = loopPrediction.startDate
        let intervalBetweenPredictedValues = 60.0 * 5.0
        for value in predictedValues {
            
            let predictedSample = NewGlucoseSample(date: currDate,
                                          quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(value)),
                                          condition: nil,
                                          trend: nil,
                                          trendRate: nil,
                                          isDisplayOnly: false,
                                          wasUserEntered: false,
                                          //TODO: Probably needs to be something unique from NS predicted data
                                          syncIdentifier:  UUID().uuidString)
            
            predictedSamples.append(predictedSample)
            currDate = currDate.addingTimeInterval(intervalBetweenPredictedValues)
        }
        
        return predictedSamples
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
    
    //MARK: RemoteDataServiceProvider
    
    func checkAuth() async throws {
        try await remoteDataProvider.checkAuth()
    }
    
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await remoteDataProvider.fetchGlucoseSamples()
    }
    
    func fetchBolusEntries() async throws -> [BolusNightscoutTreatment] {
        return try await remoteDataProvider.fetchBolusEntries()
    }
    
    func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment] {
        return try await remoteDataProvider.fetchBasalEntries()
    }
    
    func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment] {
        return try await remoteDataProvider.fetchCarbEntries()
    }
    
    func fetchOverrideEntries() async throws -> [NightscoutKit.OverrideTreatment] {
        return try await remoteDataProvider.fetchOverrideEntries()
    }
    
    func fetchLatestDeviceStatus() async throws -> DeviceStatus? {
        return try await remoteDataProvider.fetchLatestDeviceStatus()
    }
    
    func deliverCarbs(amountInGrams: Double, absorptionTime: TimeInterval, consumedDate: Date) async throws {
        return try await remoteDataProvider.deliverCarbs(amountInGrams: amountInGrams, absorptionTime: absorptionTime, consumedDate: consumedDate)
    }
    
    func deliverBolus(amountInUnits: Double) async throws {
        return try await remoteDataProvider.deliverBolus(amountInUnits: amountInUnits)
    }
    
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        return try await remoteDataProvider.startOverride(overrideName: overrideName, durationTime: durationTime)
    }
    
    func cancelOverride() async throws {
        return try await remoteDataProvider.cancelOverride()
    }
    
    func activateAutobolus(activate: Bool) async throws {
        try await remoteDataProvider.activateAutobolus(activate: activate)
    }
    func activateClosedLoop(activate: Bool) async throws {
        try await remoteDataProvider.activateClosedLoop(activate: activate)
    }
    
    func fetchCurrentProfile() async throws -> ProfileSet {
        return try await remoteDataProvider.fetchCurrentProfile()
    }
    
    func activeOverride() -> NightscoutKit.TemporaryScheduleOverride? {
        
        /*
         There are 3 sources of the current override from Nightscout
         1. Devicestatus.overrideStatus: Used by NS Plugin (bubble view)
         2. Profile.settings.scheduleOverride: Not sure what used by
         3. Override Entries: Used by NS Ticker Tape

         */
        
        //1. Devicestatus.overrideStatus
        //We would use this except it is not up-to-date when Loop events occur in the background.
        guard let overrideStatus = latestDeviceStatus?.overrideStatus, overrideStatus.active else {
            return nil
        }
  
        if let duration = overrideStatus.duration {
            if overrideStatus.timestamp.addingTimeInterval(duration) <= self.nowDate() {
                return nil
            }
        }
        
        //2.  Profile.settings.scheduleOverride
        //The override is not correct when its duration runs out so we have to check Override Entries too
        guard let override = currentProfile?.settings.scheduleOverride else {
            return nil
        }
        
        //3. Override Entries
        //We could exclusively use this, except a really old override may
        //fall outside our lookback period (i.e. indefinite override)
//        if let mostRecentOverrideEntry = overrideEntries.filter({$0.timestamp <= nowDate()})
//            .sorted(by: {$0.timestamp < $1.timestamp})
//            .last {
//            if let endDate = mostRecentOverrideEntry.endDate, endDate <= nowDate() {
//                //Entry expired - This happens when the OverrideStatus above is out of sync with the uploaded entries.
//                return nil
//            }
//        }
        
        return override
    }
    
    func fetchRecentCommands() async throws -> [RemoteCommand] {
        return try await remoteDataProvider.fetchRecentCommands()
    }
    
    func deleteAllCommands() async throws {
        try await remoteDataProvider.deleteAllCommands()
    }
}


protocol RemoteDataServiceProvider {
    func checkAuth() async throws
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample]
    func fetchBolusEntries() async throws -> [BolusNightscoutTreatment]
    func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment]
    func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment]
    func fetchOverrideEntries() async throws -> [OverrideTreatment]
    func fetchLatestDeviceStatus() async throws -> DeviceStatus?
    func deliverCarbs(amountInGrams: Double, absorptionTime: TimeInterval, consumedDate: Date) async throws
    func deliverBolus(amountInUnits: Double) async throws
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws
    func cancelOverride() async throws
    func activateAutobolus(activate: Bool) async throws
    func activateClosedLoop(activate: Bool) async throws
    func fetchCurrentProfile() async throws -> ProfileSet
    func fetchRecentCommands() async throws -> [RemoteCommand]
    func deleteAllCommands() async throws
}
