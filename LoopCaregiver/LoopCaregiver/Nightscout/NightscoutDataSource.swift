//
//  NightscoutDataSource.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/19/22.
//

import Foundation
import NightscoutClient
import LoopKit

class NightscoutDataSource: ObservableObject, RemoteDataServiceProvider {
    
    private var credentialService: NightscoutCredentialService
    private let nightscoutService: NightscoutService
    
    enum NightscoutDataSourceError: LocalizedError {
        case badOTP
    }
    
    init(looper: Looper){
        self.nightscoutService = NightscoutService(baseURL: looper.nightscoutCredentials.url, secret: looper.nightscoutCredentials.secretKey, nowDateProvider: {Date()})
        self.credentialService = NightscoutCredentialService(credentials: looper.nightscoutCredentials)
    }
    
    
    //MARK: RemoteDataServiceProvider
    
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await nightscoutService.getEGVs(startDate: fetchStartDate(), endDate:fetchEndDate())
            .map({$0.toGlucoseSample()})
    }
    
    func fetchPredictedGlucose() async throws -> [NewGlucoseSample] {
        
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
        
        return predictedEGVs.map({$0.toGlucoseSample()})
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

    
    //MARK: Lifecycle
    
    func shutdown() throws {
        try nightscoutService.syncShutdown()
    }
}




