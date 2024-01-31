//
//  RemoteDataServiceManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation
import HealthKit
import LoopKit
import NightscoutKit
import UIKit //For willEnterForegroundNotification

public class RemoteDataServiceManager: ObservableObject, RemoteDataServiceProvider {

    @Published public var currentGlucoseSample: NewGlucoseSample? = nil
    @Published public var glucoseSamples: [NewGlucoseSample] = []
    @Published public var predictedGlucose: [NewGlucoseSample] = []
    @Published public var carbEntries: [CarbCorrectionNightscoutTreatment] = []
    @Published public var bolusEntries: [BolusNightscoutTreatment] = []
    @Published public var basalEntries: [TempBasalNightscoutTreatment] = []
    @Published public var overridePresets: [OverrideTreatment] = []
    @Published public var latestDeviceStatus: DeviceStatus? = nil
    @Published public var recommendedBolus: Double? = nil
    @Published public var currentIOB: IOBStatus? = nil
    @Published public var currentCOB: COBStatus? = nil
    @Published public var currentProfile: ProfileSet?
    @Published public var recentCommands: [RemoteCommand] = []
    @Published public var updating: Bool = false
    
    private let remoteDataProvider: RemoteDataServiceProvider
    private var dateUpdateTimer: Timer?
    
    public init(remoteDataProvider: RemoteDataServiceProvider){
        self.remoteDataProvider = remoteDataProvider
    }
    
    func monitorForUpdates(updateInterval: TimeInterval = 30.0) {
        
        Task {
            await self.updateData()
        }
        
        self.dateUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true, block: { [weak self] timer in
            guard let self else { return }
            Task {
                await self.updateData()
            }
        })
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.updateData()
            }
        }
        #endif
    }
    
    @MainActor
    public func updateData() async {
        
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
            async let overridePresetsAsync = remoteDataProvider.fetchOverridePresets()
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
            
            let overridePresets = try await overridePresetsAsync
            if overridePresets != self.overridePresets {
                self.overridePresets = overridePresets
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
    
    public func checkAuth() async throws {
        try await remoteDataProvider.checkAuth()
    }
    
    public func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await remoteDataProvider.fetchGlucoseSamples()
    }
    
    public func fetchRecentGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await remoteDataProvider.fetchRecentGlucoseSamples()
    }
    
    public func fetchBolusEntries() async throws -> [BolusNightscoutTreatment] {
        return try await remoteDataProvider.fetchBolusEntries()
    }
    
    public func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment] {
        return try await remoteDataProvider.fetchBasalEntries()
    }
    
    public func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment] {
        return try await remoteDataProvider.fetchCarbEntries()
    }
    
    public func fetchOverridePresets() async throws -> [NightscoutKit.OverrideTreatment] {
        return try await remoteDataProvider.fetchOverridePresets()
    }
    
    public func fetchLatestDeviceStatus() async throws -> DeviceStatus? {
        return try await remoteDataProvider.fetchLatestDeviceStatus()
    }
    
    public func deliverCarbs(amountInGrams: Double, absorptionTime: TimeInterval, consumedDate: Date) async throws {
        return try await remoteDataProvider.deliverCarbs(amountInGrams: amountInGrams, absorptionTime: absorptionTime, consumedDate: consumedDate)
    }
    
    public func deliverBolus(amountInUnits: Double) async throws {
        return try await remoteDataProvider.deliverBolus(amountInUnits: amountInUnits)
    }
    
    public func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        return try await remoteDataProvider.startOverride(overrideName: overrideName, durationTime: durationTime)
    }
    
    public func cancelOverride() async throws {
        return try await remoteDataProvider.cancelOverride()
    }
    
    public func activateAutobolus(activate: Bool) async throws {
        try await remoteDataProvider.activateAutobolus(activate: activate)
    }
    public func activateClosedLoop(activate: Bool) async throws {
        try await remoteDataProvider.activateClosedLoop(activate: activate)
    }
    
    public func fetchCurrentProfile() async throws -> ProfileSet {
        return try await remoteDataProvider.fetchCurrentProfile()
    }
    
    public func activeOverrideAndStatus() -> (override: NightscoutKit.TemporaryScheduleOverride, status: NightscoutKit.OverrideStatus)? {
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
        
        return (override, overrideStatus)
    }
    
    public func activeOverride() -> NightscoutKit.TemporaryScheduleOverride? {
        return activeOverrideAndStatus()?.override
    }
    
    public func fetchRecentCommands() async throws -> [RemoteCommand] {
        return try await remoteDataProvider.fetchRecentCommands()
    }
    
    public func deleteAllCommands() async throws {
        try await remoteDataProvider.deleteAllCommands()
    }
}


