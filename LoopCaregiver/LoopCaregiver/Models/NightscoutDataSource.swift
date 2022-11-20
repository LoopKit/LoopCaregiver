//
//  NightscoutDataSource.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/19/22.
//

import Foundation
import NightscoutClient

class NightscoutDataSource: ObservableObject {
    
    @Published var currentEGV: NightscoutEGV? = nil
    @Published var egvs: [NightscoutEGV] = []
    @Published var carbEntries: [WGCarbEntry] = []
    @Published var bolusEntries: [WGBolusEntry] = []
    @Published var predictedEGVs: [NightscoutEGV] = []
    @Published var lastUpdate: Date = Date()
    
    let nightscoutService: NightscoutService
    
    private var timer: Timer?
    
    init(nightscoutService: NightscoutService){
        self.nightscoutService = nightscoutService
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
        try nightscoutService.syncShutdown()
    }
    
    @MainActor
    func updateData() async throws {
        
        let startDate = Date()
        var updatesOccured = false
        
        let egvs = try await fetchEGVs()
            .sorted(by: {$0.systemTime < $1.systemTime})
        if egvs != self.egvs {
            self.egvs = egvs
            updatesOccured = true
        }
        
        if let latestEGV = egvs.filter({$0.systemTime <= nowDate()}).last, latestEGV != currentEGV {
            currentEGV = latestEGV
            updatesOccured = true
        }
        
        let predictedEGVs = try await fetchPredictedEGVs()
        if predictedEGVs != self.predictedEGVs {
            self.predictedEGVs = predictedEGVs
            updatesOccured = true
        }
        
        let carbEntries = try await fetchCarbEntries()
        if carbEntries != self.carbEntries {
            self.carbEntries = carbEntries
            updatesOccured = true
        }
        
        let bolusEntries = try await fetchBolusEntries()
        if bolusEntries != self.bolusEntries {
            self.bolusEntries = bolusEntries
            updatesOccured = true
        }
        
        if updatesOccured {
            lastUpdate = nowDate()
        }
        
        print("Time to complete Nightscout update \(nowDate().timeIntervalSince(startDate)) seconds")
    }
    
    func fetchEGVs() async throws -> [NightscoutEGV] {
        return try await nightscoutService.getEGVs(startDate: fetchStartDate(), endDate:fetchEndDate())
            .sorted(by: {$0.displayTime < $1.displayTime})
    }
    
    func fetchPredictedEGVs() async throws -> [NightscoutEGV] {
        
        guard let latestDeviceStatus = try await nightscoutService.getDeviceStatuses(startDate: fetchStartDate(), endDate: fetchEndDate())
            .sorted(by: {$0.created_at < $1.created_at})
            .last else {
            return []
        }
        
        guard let predictedValues = latestDeviceStatus.loop?.predicted?.values else {
            return []
        }
        
        var predictedEGVs = [NightscoutEGV]()
        var currDate = Date()
        for value in predictedValues {
            let egv = NightscoutEGV(value: Int(value), systemTime: currDate, displayTime: currDate, realtimeValue: nil, smoothedValue: nil, trendRate: nil, trendDescription: "")
            
            predictedEGVs.append(egv)
            currDate = currDate.addingTimeInterval(60*5) //every 5 minutes
        }
        
        return predictedEGVs
    }
    
    func fetchBolusEntries() async throws -> [WGBolusEntry] {
        return try await nightscoutService.getBolusTreatments(startDate: fetchStartDate(), endDate: fetchEndDate())
    }
    
    func fetchCarbEntries() async throws -> [WGCarbEntry] {
        return try await nightscoutService.getCarbTreatments(startDate: fetchStartDate(), endDate: fetchEndDate())
    }
    
    func fetchStartDate() -> Date {
        return nowDate().addingTimeInterval(-60 * 60 * 24 * 3)
    }
    
    func fetchEndDate() -> Date {
        return nowDate().addingTimeInterval(60 * 60)
    }
    
    func nowDate() -> Date {
        return Date()
    }
}


