//
//  RemoteDataServiceManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation
import NightscoutClient
import LoopKit

class RemoteDataServiceManager: ObservableObject, RemoteDataServiceProvider {

    @Published var currentGlucoseSample: NewGlucoseSample? = nil
    @Published var glucoseSamples: [NewGlucoseSample] = []
    @Published var predictedGlucose: [NewGlucoseSample] = []
    @Published var carbEntries: [WGCarbEntry] = []
    @Published var bolusEntries: [WGBolusEntry] = []
    @Published var basalEntries: [WGBasalEntry] = []
    @Published var currentIOB: WGLoopIOB? = nil
    @Published var currentCOB: WGLoopCOB? = nil
    @Published var profiles: [NightscoutProfile] = []
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
            
            if let iob = deviceStatus.loop?.iob,
               iob != self.currentIOB {
                self.currentIOB = iob
            }
            
            if let cob = deviceStatus.loop?.cob,
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
    
    func predictedGlucoseSamples(latestDeviceStatus: NightscoutDeviceStatus) -> [NewGlucoseSample] {
        guard let loopPrediction = latestDeviceStatus.loop?.predicted else {
            return []
        }
        
        guard let predictedValues = loopPrediction.values else {
            return []
        }
        
        var predictedEGVs = [NightscoutEGV]()
        var currDate = loopPrediction.startDate
        for value in predictedValues {
            //TODO: Probably needs to be something unique from NS predicted data
            let egv = NightscoutEGV(id:  UUID().uuidString, value: Int(value), systemTime: currDate, displayTime: currDate, realtimeValue: nil, smoothedValue: nil, trendRate: nil, trendDescription: "")
            
            predictedEGVs.append(egv)
            currDate = currDate.addingTimeInterval(60*5) //every 5 minutes
        }
        
        return predictedEGVs.map({$0.toGlucoseSample()})
            .sorted(by: {$0.date < $1.date})
    }
    
    @MainActor
    func updateInfrequentData() async throws {

        async let profilesAsync = remoteDataProvider.getProfiles()
        
        let profiles = try await profilesAsync
        if profiles != self.profiles {
            self.profiles = profiles
        }
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
    
    //MARK: RemoteDataServiceProvider
    
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await remoteDataProvider.fetchGlucoseSamples()
    }
    
    func fetchBolusEntries() async throws -> [NightscoutClient.WGBolusEntry] {
        return try await remoteDataProvider.fetchBolusEntries()
    }
    
    func fetchBasalEntries() async throws -> [NightscoutClient.WGBasalEntry] {
        return try await remoteDataProvider.fetchBasalEntries()
    }
    
    func fetchCarbEntries() async throws -> [NightscoutClient.WGCarbEntry] {
        return try await remoteDataProvider.fetchCarbEntries()
    }
    
    func fetchLatestDeviceStatus() async throws -> NightscoutDeviceStatus? {
        return try await remoteDataProvider.fetchLatestDeviceStatus()
    }
    
    func deliverCarbs(amountInGrams: Double, durationInHours: Float, consumedDate: Date) async throws {
        return try await remoteDataProvider.deliverCarbs(amountInGrams: amountInGrams, durationInHours: durationInHours, consumedDate: consumedDate)
    }
    
    func deliverBolus(amountInUnits: Double) async throws {
        return try await remoteDataProvider.deliverBolus(amountInUnits: amountInUnits)
    }
    
    func startOverride(overrideName: String, overrideDisplay: String, durationInMinutes: Int) async throws {
        return try await remoteDataProvider.startOverride(overrideName: overrideName, overrideDisplay: overrideDisplay, durationInMinutes: durationInMinutes)
    }
    
    func cancelOverride() async throws {
        return try await remoteDataProvider.cancelOverride()
    }
    
    func getProfiles() async throws -> [NightscoutClient.NightscoutProfile] {
        return try await remoteDataProvider.getProfiles()
    }
    
    
    //MARK: Lifecycle
    
    func shutdown() throws {
        try remoteDataProvider.shutdown()
    }
}


protocol RemoteDataServiceProvider {
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample]
    func fetchBolusEntries() async throws -> [WGBolusEntry]
    func fetchBasalEntries() async throws -> [WGBasalEntry]
    func fetchCarbEntries() async throws -> [WGCarbEntry]
    func fetchLatestDeviceStatus() async throws -> NightscoutDeviceStatus?
    func deliverCarbs(amountInGrams: Double, durationInHours: Float, consumedDate: Date) async throws
    func deliverBolus(amountInUnits: Double) async throws
    func startOverride(overrideName: String, overrideDisplay: String, durationInMinutes: Int) async throws
    func cancelOverride() async throws
    func getProfiles() async throws -> [NightscoutProfile]
    func shutdown() throws
}
