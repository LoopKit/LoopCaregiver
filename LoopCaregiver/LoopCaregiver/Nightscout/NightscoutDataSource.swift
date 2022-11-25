//
//  NightscoutDataSource.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/19/22.
//

import Foundation
import NightscoutClient

class NightscoutDataSource: ObservableObject, RemoteDataServiceProvider {
    
    @Published var currentEGV: NightscoutEGV? = nil
    @Published var egvs: [NightscoutEGV] = []
    @Published var carbEntries: [WGCarbEntry] = []
    @Published var bolusEntries: [WGBolusEntry] = []
    @Published var predictedEGVs: [NightscoutEGV] = []
    @Published var currentIOB: WGLoopIOB? = nil
    @Published var currentCOB: WGLoopCOB? = nil
    @Published var updating: Bool = false
    
    var credentialService: NightscoutCredentialService
    
    private let nightscoutService: NightscoutService
    private var timer: Timer?
    
    enum NightscoutDataSourceError: LocalizedError {
        case badOTP
    }
    
    init(looper: Looper){
        self.nightscoutService = NightscoutService(baseURL: looper.nightscoutCredentials.url, secret: looper.nightscoutCredentials.secretKey, nowDateProvider: {Date()})
        self.credentialService = NightscoutCredentialService(credentials: looper.nightscoutCredentials)
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
        updating = true
        let egvs = try await fetchEGVs()
            .sorted(by: {$0.systemTime < $1.systemTime})
        if egvs != self.egvs {
            self.egvs = egvs
        }
        
        if let latestEGV = egvs.filter({$0.systemTime <= nowDate()}).last, latestEGV != currentEGV {
            currentEGV = latestEGV
        }
        
        async let predictedEGVAsync = fetchPredictedEGVs()
        async let carbEntriesAsync = fetchCarbEntries()
        async let bolusEntriesAsync = fetchBolusEntries()
        async let deviceStatusesAsync = fetchDeviceStatuses()
        
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
    
    //MARK: RemoteDataServiceProvider
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
        
        return predictedEGVs
    }
    
    func fetchBolusEntries() async throws -> [WGBolusEntry] {
        return try await nightscoutService.getBolusTreatments(startDate: fetchStartDate(), endDate: fetchEndDate())
    }
    
    func fetchCarbEntries() async throws -> [WGCarbEntry] {
        return try await nightscoutService.getCarbTreatments(startDate: fetchStartDate(), endDate: fetchEndDate())
    }
    
    func fetchDeviceStatuses() async throws -> [NightscoutDeviceStatus] {
        return try await nightscoutService.getDeviceStatuses(startDate: fetchStartDate(), endDate: fetchEndDate())
    }
    
    func fetchStartDate() -> Date {
        return nowDate().addingTimeInterval(-60 * 60 * 24 * 1)
    }
    
    func fetchEndDate() -> Date {
        return nowDate().addingTimeInterval(60 * 60)
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
    
    //MARK: Actions
    
    func deliverCarbs(amountInGrams: Int, durationInHours: Float) async throws {
        guard let otpCodeInt = Int(credentialService.otpCode) else {
            throw NightscoutDataSourceError.badOTP
        }
        let _ = try await nightscoutService.deliverCarbs(amountInGrams: amountInGrams, amountInHours: durationInHours, otp: otpCodeInt)
    }
    
    func deliverBolus(amountInUnits: Double) async throws {
        guard let otpCodeInt = Int(credentialService.otpCode) else {
            throw NightscoutDataSourceError.badOTP
        }
        let _ = try await nightscoutService.deliverBolus(amountInUnits: amountInUnits, otp: otpCodeInt)
    }
    
    func startOverride(overrideName: String, overrideDisplay: String, durationInMinutes: Int) async throws {
        let _ = try await nightscoutService.startOverride(overrideName: overrideName, overrideDisplay: overrideDisplay, durationInMinutes: durationInMinutes)
    }
    
    func cancelOverride() async throws {
        let _ = try await nightscoutService.cancelOverride()
    }
    
    func getProfiles() async throws -> [NightscoutProfile] {
        return try await nightscoutService.getProfiles()
    }

}




