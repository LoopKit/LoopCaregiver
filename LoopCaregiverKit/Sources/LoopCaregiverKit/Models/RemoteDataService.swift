//
//  RemoteDataService.swift
//
//
//  Created by Bill Gestrich on 12/15/23.
//

import Foundation
import LoopKit
import NightscoutKit

public protocol RemoteDataServiceProvider {
    func checkAuth() async throws
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample]
    func fetchRecentGlucoseSamples() async throws -> [NewGlucoseSample]
    func fetchBolusEntries() async throws -> [BolusNightscoutTreatment]
    func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment]
    func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment]
    func fetchOverridePresets() async throws -> [OverrideTreatment]
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
