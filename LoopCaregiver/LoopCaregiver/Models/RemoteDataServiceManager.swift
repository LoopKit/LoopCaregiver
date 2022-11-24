//
//  RemoteDataServiceManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation
import NightscoutClient

class RemoteDataServiceManager {
    @Published var currentEGV: NightscoutEGV? = nil
    @Published var egvs: [NightscoutEGV] = []
    @Published var carbEntries: [WGCarbEntry] = []
    @Published var bolusEntries: [WGBolusEntry] = []
    @Published var predictedEGVs: [NightscoutEGV] = []
    @Published var currentIOB: WGLoopIOB? = nil
    @Published var currentCOB: WGLoopCOB? = nil
    @Published var updating: Bool = false
    
    private let remoteDataProvider: RemoteDataServiceProvider
    private var timer: Timer?
    
    init(looper: Looper){
        self.remoteDataProvider = NightscoutDataSource(looper: looper)
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
    
    func shutdown() throws {
        try remoteDataProvider.shutdown()
    }
    
    @MainActor
    func updateData() async throws {
        updating = true
        let egvs = try await remoteDataProvider.fetchEGVs()
            .sorted(by: {$0.systemTime < $1.systemTime})
        if egvs != self.egvs {
            self.egvs = egvs
        }
        
        if let latestEGV = egvs.filter({$0.systemTime <= nowDate()}).last, latestEGV != currentEGV {
            currentEGV = latestEGV
        }
        
        async let predictedEGVAsync = remoteDataProvider.fetchPredictedEGVs()
        async let carbEntriesAsync = remoteDataProvider.fetchCarbEntries()
        async let bolusEntriesAsync = remoteDataProvider.fetchBolusEntries()
        async let deviceStatusesAsync = remoteDataProvider.fetchDeviceStatuses()
        
        let predictedEGVs = try await predictedEGVAsync
        if predictedEGVs != self.predictedEGVs {
            self.predictedEGVs = predictedEGVs
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
}


protocol RemoteDataServiceProvider {
    func fetchEGVs() async throws -> [NightscoutEGV]
    func fetchPredictedEGVs() async throws -> [NightscoutEGV]
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
