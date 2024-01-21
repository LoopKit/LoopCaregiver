//
//  RemoteDataServiceProviderSimulator.swift
//
//
//  Created by Bill Gestrich on 1/17/24.
//

import Foundation
import LoopKit
import NightscoutKit

public class RemoteDataServiceProviderSimulator: RemoteDataServiceProvider {
    
    public init() {
        
    }
    
    public func checkAuth() async throws {
        
    }
    
    public func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        let sample = NewGlucoseSample(date: Date(), quantity: .init(unit: .milligramsPerDeciliter, doubleValue: 100.0), condition: .none, trend: .flat, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "1345")
        return [sample]
    }
    
    
    public func fetchRecentGlucoseSamples() async throws -> [NewGlucoseSample] {
        return try await fetchGlucoseSamples()
    }
    
    public func fetchBolusEntries() async throws -> [BolusNightscoutTreatment] {
        return []
    }
    
    public func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment] {
        return []
    }
    
    public func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment] {
        return []
    }
    
    public func fetchOverridePresets() async throws -> [OverrideTreatment] {
        return []
    }
    
    public func fetchLatestDeviceStatus() async throws -> DeviceStatus? {
        return nil
    }
    
    public func deliverCarbs(amountInGrams: Double, absorptionTime: TimeInterval, consumedDate: Date) async throws {
        
    }
    
    public func deliverBolus(amountInUnits: Double) async throws {
        
    }
    
    public func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        
    }
    
    public func cancelOverride() async throws {
        
    }
    
    public func activateAutobolus(activate: Bool) async throws {
        
    }
    
    public func activateClosedLoop(activate: Bool) async throws {
        
    }
    
    public func fetchCurrentProfile() async throws -> ProfileSet {
        throw RemoteDataServiceProviderSimulatorError.unsupported
    }
    
    public func fetchRecentCommands() async throws -> [RemoteCommand] {
        return []
    }
    
    public func deleteAllCommands() async throws {
    }
    
    enum RemoteDataServiceProviderSimulatorError: Error {
        case unsupported
    }
    
}
