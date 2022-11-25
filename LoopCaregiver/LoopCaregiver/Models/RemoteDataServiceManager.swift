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
    @Published var currentIOB: WGLoopIOB? = nil
    @Published var currentCOB: WGLoopCOB? = nil
    @Published var updating: Bool = false
    
    private let remoteDataProvider: RemoteDataServiceProvider
    private var timer: Timer?
    
    init(remoteDataProvider: RemoteDataServiceProvider){
        self.remoteDataProvider = remoteDataProvider
        monitorForUpdates(updateInterval: 30)
    }
    
    func monitorForUpdates(updateInterval: TimeInterval) {
        self.timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true, block: { timer in
            Task {
                try await self.updateData()
            }
        })
        
        Task {
            try await self.updateData()
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
        
        async let predictedGlucoseAsync = remoteDataProvider.fetchPredictedGlucose()
        async let carbEntriesAsync = remoteDataProvider.fetchCarbEntries()
        async let bolusEntriesAsync = remoteDataProvider.fetchBolusEntries()
        async let deviceStatusesAsync = remoteDataProvider.fetchDeviceStatuses()
        
        let predictedGlucoseSamples = try await predictedGlucoseAsync
            .sorted(by: {$0.date < $1.date})
        if predictedGlucoseSamples != self.predictedGlucose {
            self.predictedGlucose = predictedGlucoseSamples
        }

        let carbEntries = try await carbEntriesAsync
        if carbEntries != self.carbEntries {
            self.carbEntries = carbEntries
        }
        
        let bolusEntries = try await bolusEntriesAsync
        if bolusEntries != self.bolusEntries {
            self.bolusEntries = bolusEntries
        }
        
        let deviceStatuses = try await deviceStatusesAsync
            .sorted(by: {$0.created_at < $1.created_at})
        if let iob = deviceStatuses.last?.loop?.iob,
           iob != self.currentIOB {
            self.currentIOB = iob
        }
        if let cob = deviceStatuses.last?.loop?.cob,
           cob != self.currentCOB {
            self.currentCOB = cob
        }
        updating = false
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
    
    //MARK: RemoteDataServiceProvider
    
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await remoteDataProvider.fetchGlucoseSamples()
    }
    
    func fetchPredictedGlucose() async throws -> [NewGlucoseSample] {
        return try await remoteDataProvider.fetchPredictedGlucose()
    }
    
    func fetchBolusEntries() async throws -> [NightscoutClient.WGBolusEntry] {
        return try await remoteDataProvider.fetchBolusEntries()
    }
    
    func fetchCarbEntries() async throws -> [NightscoutClient.WGCarbEntry] {
        return try await remoteDataProvider.fetchCarbEntries()
    }
    
    func fetchDeviceStatuses() async throws -> [NightscoutClient.NightscoutDeviceStatus] {
        return try await remoteDataProvider.fetchDeviceStatuses()
    }
    
    func deliverCarbs(amountInGrams: Int, durationInHours: Float) async throws {
        return try await remoteDataProvider.deliverCarbs(amountInGrams: amountInGrams, durationInHours: durationInHours)
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
    func fetchPredictedGlucose() async throws -> [NewGlucoseSample]
    func fetchBolusEntries() async throws -> [WGBolusEntry]
    func fetchCarbEntries() async throws -> [WGCarbEntry]
    func fetchDeviceStatuses() async throws -> [NightscoutDeviceStatus]
    func deliverCarbs(amountInGrams: Int, durationInHours: Float) async throws
    func deliverBolus(amountInUnits: Double) async throws
    func startOverride(overrideName: String, overrideDisplay: String, durationInMinutes: Int) async throws
    func cancelOverride() async throws
    func getProfiles() async throws -> [NightscoutProfile]
    func shutdown() throws
}
