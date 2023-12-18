//
//  TimelineProvider.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 12/18/23.
//

import Foundation
import LoopCaregiverKit
import LoopKit
import SwiftUI
import WidgetKit

struct TimelineProvider: AppIntentTimelineProvider {

    //MARK: Caregiver Services
    
    let composer = ServiceComposer()
    
    var accountServiceManager: AccountServiceManager {
        return AccountServiceManager(accountService: composer.accountServiceManager)
    }
    
    func remoteDataSource(looper: Looper) -> RemoteDataServiceProvider {
        return NightscoutDataSource(looper: looper, settings: composer.settings)
    }
    
    @available(*, renamed: "getEntry()")
    func getEntry(completion: @escaping (SimpleEntry) -> Void ) {
        Task {
            let result = await getEntry()
            completion(result)
        }
    }
    
    func getEntry() async -> SimpleEntry {
        return await withCheckedContinuation { continuation in
            Task {
                
                var looper: Looper
                if let configurationLooper = getLooper() {
                    looper = configurationLooper
                } else if let selectedLooper = accountServiceManager.selectedLooper {
                    looper = selectedLooper
                } else {
                    continuation.resume(returning: SimpleEntry(currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true))
                    return
                }
                
                let nightscoutDataSource = remoteDataSource(looper: looper)
                let sortedSamples = try await nightscoutDataSource.fetchGlucoseSamples().sorted(by: {$0.date < $1.date})
                let latestGlucoseSample = sortedSamples.last
                let glucoseChange = getLastGlucoseChange(samples: sortedSamples)
                
                continuation.resume(returning: SimpleEntry(currentGlucoseSample: latestGlucoseSample, lastGlucoseChange: glucoseChange, date: Date(), entryIndex: 0, isLastEntry: true))
            }
        }
    }
    
    func getLooper() -> Looper? {
        return accountServiceManager.selectedLooper
    }
    
    func getLastGlucoseChange(samples: [NewGlucoseSample]) -> Double? {
        guard samples.count > 1 else {
            return nil
        }
        let lastGlucoseValue = samples[samples.count - 1].presentableUserValue(displayUnits: composer.settings.glucoseDisplayUnits)
        let priorGlucoseValue = samples[samples.count - 2].presentableUserValue(displayUnits: composer.settings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        return await getEntry()
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = await getEntry()
        
        var entries = [SimpleEntry]()
        let nowDate = Date()
        
        var nextRequestDate: Date = nowDate.addingTimeInterval(60*5) //Default interval
        if let nextExpectedGlucoseDate = entry.nextExpectedGlucoseDate(), nextExpectedGlucoseDate > nowDate {
            nextRequestDate = nextExpectedGlucoseDate.addingTimeInterval(60*1) //Extra minute to allow time for upload.
        }
        
        let indexCount = 60
        for index in 0..<indexCount {
            let isLastEntry = index == (indexCount - 1)
            let futureEntry = SimpleEntry(currentGlucoseSample: entry.currentGlucoseSample,
                                          lastGlucoseChange: entry.lastGlucoseChange,
                                          date: nowDate.addingTimeInterval(60 * TimeInterval(index)),
                                          entryIndex: index,
                                          isLastEntry: isLastEntry)
            entries.append(futureEntry)
        }
        return Timeline(entries: entries, policy: .after(nextRequestDate))
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Loop Caregiver Widget"),
        ]
    }
}
