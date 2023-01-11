//
//  RemoteDataServiceManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation
import LoopKit
import NightscoutUploadKit
import HealthKit

class RemoteDataServiceManager: ObservableObject, RemoteDataServiceProvider {

    @Published var currentGlucoseSample: NewGlucoseSample? = nil
    @Published var glucoseSamples: [NewGlucoseSample] = []
    @Published var predictedGlucose: [NewGlucoseSample] = []
    @Published var carbEntries: [CarbCorrectionNightscoutTreatment] = []
    @Published var bolusEntries: [BolusNightscoutTreatment] = []
    @Published var basalEntries: [TempBasalNightscoutTreatment] = []
    @Published var currentIOB: IOBStatus? = nil
    @Published var currentCOB: COBStatus? = nil
    @Published var currentProfile: ProfileSet?
    @Published var updating: Bool = false
    
    private let remoteDataProvider: RemoteDataServiceProvider
    private var dateUpdateTimer: Timer?
    private var infrequentDataUpdateTimer: Timer?
    
    init(remoteDataProvider: RemoteDataServiceProvider){
        self.remoteDataProvider = remoteDataProvider
        monitorForUpdates(updateInterval: 30)
    }
    
    func monitorForUpdates(updateInterval: TimeInterval) {
        self.dateUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true, block: { timer in
            Task {
                try await self.updateData()
            }
        })
        
        self.infrequentDataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60 * 30, repeats: true, block: { timer in
            Task {
                try await self.updateInfrequentData()
            }
        })
        
        Task {
            try await self.updateData()
            try await self.updateInfrequentData()
        }
    }
    
    @MainActor
    func updateData() async throws {
        
        updating = true
        
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
        async let deviceStatusAsync = remoteDataProvider.fetchLatestDeviceStatus()

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
        
        if let deviceStatus = try await deviceStatusAsync {
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
        
        updating = false
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

    @MainActor
    func updateInfrequentData() async throws {

        async let curentProfileAsync = remoteDataProvider.fetchCurrentProfile()
        
        let currentProfile = try await curentProfileAsync
        if currentProfile != self.currentProfile {
            self.currentProfile = currentProfile
        }
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
    
    //MARK: RemoteDataServiceProvider
    
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
    
    func fetchCurrentProfile() async throws -> ProfileSet {
        return try await remoteDataProvider.fetchCurrentProfile()
    }
}


protocol RemoteDataServiceProvider {
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample]
    func fetchBolusEntries() async throws -> [BolusNightscoutTreatment]
    func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment]
    func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment]
    func fetchLatestDeviceStatus() async throws -> DeviceStatus?
    func deliverCarbs(amountInGrams: Double, absorptionTime: TimeInterval, consumedDate: Date) async throws
    func deliverBolus(amountInUnits: Double) async throws
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws
    func cancelOverride() async throws
    func fetchCurrentProfile() async throws -> ProfileSet
}
