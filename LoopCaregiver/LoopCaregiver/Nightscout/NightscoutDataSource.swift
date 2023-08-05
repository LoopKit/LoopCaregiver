//
//  NightscoutDataSource.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/19/22.
//

import Foundation
import LoopKit
import NightscoutKit

class NightscoutDataSource: ObservableObject, RemoteDataServiceProvider {
    
    private var credentialService: NightscoutCredentialService
    private let nightscoutUploader: NightscoutClient
    private let settings: CaregiverSettings
    private let treatmentsFetcher: NightscoutTreatmentFetcher
    
    init(looper: Looper, settings: CaregiverSettings){
        self.nightscoutUploader = NightscoutClient(siteURL: looper.nightscoutCredentials.url, apiSecret: looper.nightscoutCredentials.secretKey)
        self.credentialService = NightscoutCredentialService(credentials: looper.nightscoutCredentials)
        self.settings = settings
        self.treatmentsFetcher = NightscoutTreatmentFetcher(nightscoutClient: self.nightscoutUploader,
                                                           fetchLookbackInterval: Self.fetchLookbackInterval(),
                                                           fetchLookAheadInterval: Self.fetchLookAheadInterval(),
                                                           maxFetchCount: Self.maxFetchCount()
        )
    }
    
    
    //MARK: RemoteDataServiceProvider
    
    func fetchGlucoseSamples() async throws -> [NewGlucoseSample] {
        let result = try await withCheckedThrowingContinuation({ continuation in
            nightscoutUploader.fetchGlucose(dateInterval: fetchInterval(), maxCount: maxFetchCount()) { result in
                continuation.resume(with: result)
            }
        })
        .map({$0.toGlucoseSample()})
        assert(result.count < maxFetchCount(), "Hit max count: Consider increasing")
        return result
    }
    
    func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment] {
        return try await treatmentsFetcher.fetchBasalEntries()
    }
    
    func fetchBolusEntries() async throws -> [BolusNightscoutTreatment] {
        return try await treatmentsFetcher.fetchBolusEntries()
    }
    
    func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment] {
        return try await treatmentsFetcher.fetchCarbEntries()
    }
    
    func fetchOverrideEntries() async throws -> [OverrideTreatment] {
        return try await treatmentsFetcher.fetchOverrideEntries()
    }

    func fetchNotes() async throws -> [NoteNightscoutTreatment] {
        return try await treatmentsFetcher.fetchNotes()
    }
    
    func fetchLatestDeviceStatus() async throws -> DeviceStatus? {
        let result = try await withCheckedThrowingContinuation({ continuation in
            let fetchInterval = DateInterval(start: fetchEndDate().addingTimeInterval(-60*60*2), end: fetchEndDate())
            nightscoutUploader.fetchDeviceStatus(dateInterval: fetchInterval) { result in
                continuation.resume(with: result)
            }
        })
        .sorted(by: {$0.timestamp < $1.timestamp})
        return result.last
    }
    
    func fetchStartDate() -> Date {
        return nowDate().addingTimeInterval(Self.fetchLookbackInterval())
    }
    
    static func fetchLookbackInterval() -> TimeInterval {
        return -60 * 60 * 24 * 1
    }
    
    func fetchEndDate() -> Date {
        return nowDate().addingTimeInterval(Self.fetchLookAheadInterval())
    }
    
    static func fetchLookAheadInterval() -> TimeInterval {
        return 60 * 60
    }
    
    func fetchInterval() -> DateInterval {
        return DateInterval(start: fetchStartDate(), end: fetchEndDate())
    }
    
    func maxFetchCount() -> Int {
        return Self.maxFetchCount()
    }
    
    static func maxFetchCount() -> Int {
        let seconds = abs(Self.fetchLookbackInterval()) + abs(Self.fetchLookbackInterval())
        let minutes = seconds / 60
        // Assume up to 2 entries every 1 minute.
        // We tried 1 entry per 5 minutes for bg, mulitplied by a factor for 2,
        // but this was not enoughf for some users.
        return Int(minutes * 2)
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
    func checkAuth() async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) -> Void in
            nightscoutUploader.checkAuth { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: Void())
                }
            }
        })
    }
    
    func deliverCarbs(amountInGrams: Double, absorptionTime: TimeInterval, consumedDate: Date) async throws {
        //TODO: Ensure you get a valid OTP (non-empty String)
        if settings.remoteCommands2Enabled {
            let action = NSRemoteAction.carbs(amountInGrams: amountInGrams, absorptionTime: absorptionTime, startDate: consumedDate)
            let commandPayload = createPendingCommand(action: action)
            let _ = try await nightscoutUploader.uploadRemoteCommand(commandPayload)
        } else {
            try await nightscoutUploader.deliverCarbs(amountInGrams: amountInGrams, absorptionTime: absorptionTime, consumedDate: consumedDate, otp: credentialService.otpCode)
        }
    }
    
    func deliverBolus(amountInUnits: Double) async throws {
        //TODO: Ensure you get a valid OTP (non-empty String)
        if settings.remoteCommands2Enabled {
            let action = NSRemoteAction.bolus(amountInUnits: amountInUnits)
            let commandPayload = createPendingCommand(action: action)
            let _ = try await nightscoutUploader.uploadRemoteCommand(commandPayload)
        } else {
            try await nightscoutUploader.deliverBolus(amountInUnits: amountInUnits, otp: credentialService.otpCode)
        }
    }
    
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        if settings.remoteCommands2Enabled {
            //TODO: remoteAddress should be optional
            let action = NSRemoteAction.override(name: overrideName, durationTime: durationTime, remoteAddress: "")
            let commandPayload = createPendingCommand(action: action)
            let _ = try await nightscoutUploader.uploadRemoteCommand(commandPayload)
        } else {
            try await nightscoutUploader.startOverride(overrideName: overrideName, reasonDisplay: "Caregiver Update", durationTime: durationTime)
        }
    }
    
    func cancelOverride() async throws {
        if settings.remoteCommands2Enabled {
            //TODO: remoteAddress should be optional
            let action = NSRemoteAction.cancelOverride(remoteAddress: "")
            let commandPayload = createPendingCommand(action: action)
            let _ = try await nightscoutUploader.uploadRemoteCommand(commandPayload)
        } else {
            try await nightscoutUploader.cancelOverride()
        }
    }
    
    func activateAutobolus(activate: Bool) async throws {
        let action = NSRemoteAction.autobolus(active: activate)
        let commandPayload = createPendingCommand(action: action)
        let _ = try await nightscoutUploader.uploadRemoteCommand(commandPayload)
    }
    
    func activateClosedLoop(activate: Bool) async throws {
        let action = NSRemoteAction.closedLoop(active: activate)
        let commandPayload = createPendingCommand(action: action)
        let _ = try await nightscoutUploader.uploadRemoteCommand(commandPayload)
    }
    
    func fetchCurrentProfile() async throws -> ProfileSet {
        return try await withCheckedThrowingContinuation { continuation in
            nightscoutUploader.fetchCurrentProfile{ result in
                continuation.resume(with: result)
            }
        }
    }
    
    func createPendingCommand(action: NSRemoteAction) -> NSRemoteCommandPayload {
        return NSRemoteCommandPayload(version: "2.0", createdDate: Date(), action: action, sendNotification: true, status: .init(state: .Pending, message: ""), otp: credentialService.otpCode)
    }
    
    func fetchRecentCommands() async throws -> [RemoteCommand] {
        if settings.remoteCommands2Enabled {
            return try await nightscoutUploader.fetchRemoteCommands(earliestDate: fetchInterval().start, commandState: nil).compactMap({try? $0.toRemoteCommand()})
        } else {
            return try await fetchNotes()
                .compactMap({$0.toRemoteCommand()})
        }
    }
    
    func deleteAllCommands() async throws {
        if settings.remoteCommands2Enabled {
            try await nightscoutUploader.deleteRemoteCommands()
        } else {
            assertionFailure("Remote 2.0 commands are not enabled.")
        }
    }
}

actor NightscoutTreatmentFetcher {
    
    private weak var nightscoutClient: NightscoutClient?
    private var lastTreatmentFetch: (fetchDate: Date, treatments: [NightscoutTreatment])? = nil
    private var fetchTaskInProgress: Task<[NightscoutTreatment], Error>? = nil
    private let fetchLookbackInterval: TimeInterval
    private let fetchLookAheadInterval: TimeInterval
    private let maxFetchCount: Int

    init(nightscoutClient: NightscoutClient,
         fetchLookbackInterval: TimeInterval,
         fetchLookAheadInterval: TimeInterval,
         maxFetchCount: Int
    ) {
        self.nightscoutClient = nightscoutClient
        self.fetchLookbackInterval = fetchLookbackInterval
        self.fetchLookAheadInterval = fetchLookAheadInterval
        self.maxFetchCount = maxFetchCount
    }
    
    func fetchBasalEntries() async throws -> [TempBasalNightscoutTreatment] {
        return try await fetchTreatments()
            .basalTreatments()
    }
    
    func fetchBolusEntries() async throws -> [BolusNightscoutTreatment] {
        return try await fetchTreatments()
            .bolusTreatments()
    }
    
    func fetchCarbEntries() async throws -> [CarbCorrectionNightscoutTreatment] {
        return try await fetchTreatments()
            .carbTreatments()
    }
    
    func fetchOverrideEntries() async throws -> [OverrideTreatment] {
        return try await fetchTreatments()
            .overrideTreatments()
    }
    
    func fetchNotes() async throws -> [NoteNightscoutTreatment] {
        return try await fetchTreatments()
            .noteTreatments()
    }

    func fetchTreatments() async throws -> [NightscoutTreatment] {
        if let ongoingFetch = fetchTaskInProgress {
            return try await ongoingFetch.value
        } else if let validCachedTreatments = getValidCachedTreatments() {
            return validCachedTreatments
        } else {
            let task = Task { [self] in
                do {
                    let treatments = try await fetchTreatmentsNoCache()
                    fetchTaskInProgress = nil
                    lastTreatmentFetch = (fetchDate: Date(), treatments: treatments)
                    return treatments
                } catch {
                    fetchTaskInProgress = nil
                    throw error
                }
            }
            fetchTaskInProgress = task
            let treatments = try await task.value
            storeCachedTreatments(treatments: treatments)
            return treatments
        }
    }
    
    func fetchTreatmentsNoCache() async throws -> [NightscoutTreatment] {
        guard let nightscoutClient = self.nightscoutClient else {return []}
        let result = try await withCheckedThrowingContinuation({ continuation in
            nightscoutClient.fetchTreatments(dateInterval: fetchInterval(), maxCount: maxFetchCount) { result in
                continuation.resume(with: result)
            }
        })

        return result
    }

    
    private func storeCachedTreatments(treatments: [NightscoutTreatment]) {
        lastTreatmentFetch = (fetchDate: Date(), treatments: treatments)
    }
    
    private func getValidCachedTreatments() -> [NightscoutTreatment]? {
        guard let lastTreatmentFetch = lastTreatmentFetch else {
            return nil
        }
        
        let now = nowDate()
        
        guard lastTreatmentFetch.fetchDate <= now else {
            return nil //Future date - invalid
        }
        
        guard lastTreatmentFetch.fetchDate >= now.addingTimeInterval(-15) else {
            return nil
        }
        
        return lastTreatmentFetch.treatments
    }
    
    private func nowDate() -> Date {
        return Date()
    }
    
    private func fetchStartDate() -> Date {
        return nowDate().addingTimeInterval(fetchLookbackInterval)
    }
    
    func fetchEndDate() -> Date {
        return nowDate().addingTimeInterval(fetchLookAheadInterval)
    }
    
    func fetchInterval() -> DateInterval {
        return DateInterval(start: fetchStartDate(), end: fetchEndDate())
    }
}
