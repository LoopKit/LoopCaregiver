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

class TimelineProvider: AppIntentTimelineProvider {
    
    /// Shows the first time widget appears on watchface and when redacted
    func placeholder(in context: Context) -> SimpleEntry {
        let composer = ServiceComposerProduction()
        return SimpleEntry(looper: nil, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true, glucoseDisplayUnits: composer.settings.glucoseDisplayUnits)
    }
    
    /// Used to recommend Looper configurations on Watch only since WatchOS
    /// does not offer a dedicated interface for configurations.
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        var result: [AppIntentRecommendation<ConfigurationAppIntent>] = []
        let composer = ServiceComposerProduction()
        do {
            let availableLoopers = try composer.accountServiceManager.getLoopers()
            result = availableLoopers.compactMap({ looper in
                let appIntent = ConfigurationAppIntent(looperID: looper.id, name: looper.name)
                guard let name = appIntent.name else {return nil}
                return AppIntentRecommendation(intent: appIntent, description: name)
            })
        } catch {
            print(error)
        }
        
        return result
    }
    
    /// Shows when widget is in the gallery and other "transient" times per docs.
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // Docs suggest returning quickly when context.isPreview is true although we probably never want fake data
        return await getEntry(composer: ServiceComposerProduction(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let composer = ServiceComposerProduction()
        let entry = await getEntry(composer: composer, configuration: configuration)
        
        var entries = [SimpleEntry]()
        let nowDate = Date()
        
        var nextRequestDate: Date = nowDate.addingTimeInterval(60*5) //Default interval
        if let nextExpectedGlucoseDate = entry.nextExpectedGlucoseDate(), nextExpectedGlucoseDate > nowDate {
            nextRequestDate = nextExpectedGlucoseDate.addingTimeInterval(60*1) //Extra minute to allow time for upload.
        }
        
        let indexCount = 60
        for index in 0..<indexCount {
            let isLastEntry = index == (indexCount - 1)
            let futureEntry = SimpleEntry(looper: entry.looper, currentGlucoseSample: entry.currentGlucoseSample,
                                          lastGlucoseChange: entry.lastGlucoseChange,
                                          date: nowDate.addingTimeInterval(60 * TimeInterval(index)),
                                          entryIndex: index,
                                          isLastEntry: isLastEntry,
                                          glucoseDisplayUnits: composer.settings.glucoseDisplayUnits)
            entries.append(futureEntry)
        }
        return Timeline(entries: entries, policy: .after(nextRequestDate))
    }
    
    func getEntry(composer: ServiceComposer, configuration: ConfigurationAppIntent) async -> SimpleEntry {
        return await withCheckedContinuation { continuation in
            Task {
                
                var looper: Looper
                if let configurationLooper = try composer.accountServiceManager.getLoopers().first(where: {$0.id == configuration.looperID}) {
                    looper = configurationLooper
                } else {
                    continuation.resume(returning: SimpleEntry(looper: nil, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true, glucoseDisplayUnits: composer.settings.glucoseDisplayUnits))
                    return
                }
                
                let nightscoutDataSource = NightscoutDataSource(looper: looper, settings: composer.settings)
                let sortedSamples = try await nightscoutDataSource.fetchRecentGlucoseSamples().sorted(by: {$0.date < $1.date})
                let latestGlucoseSample = sortedSamples.last
                let glucoseChange = getLastGlucoseChange(composer: composer, samples: sortedSamples)
                
                continuation.resume(returning: SimpleEntry(looper: looper, currentGlucoseSample: latestGlucoseSample, lastGlucoseChange: glucoseChange, date: Date(), entryIndex: 0, isLastEntry: true, glucoseDisplayUnits: composer.settings.glucoseDisplayUnits))
            }
        }
    }
    
    // The widget does not show in the gallery for some reason when using async directory.
    /*
    func getEntry(composer: ServiceComposer, configuration: ConfigurationAppIntent) async -> SimpleEntry {
        do {
            var looper: Looper
            if let configurationLooper = try composer.accountServiceManager.getLoopers().first(where: {$0.id == configuration.looperID}) {
                looper = configurationLooper
            } else {
                return SimpleEntry(looper: nil, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true, glucoseDisplayUnits: composer.settings.glucoseDisplayUnits)
            }
            
            let nightscoutDataSource = NightscoutDataSource(looper: looper, settings: composer.settings)
            let sortedSamples = try await nightscoutDataSource.fetchRecentGlucoseSamples().sorted(by: {$0.date < $1.date})
            let latestGlucoseSample = sortedSamples.last
            let glucoseChange = getLastGlucoseChange(composer: composer, samples: sortedSamples)
            
            return SimpleEntry(looper: looper, currentGlucoseSample: latestGlucoseSample, lastGlucoseChange: glucoseChange, date: Date(), entryIndex: 0, isLastEntry: true, glucoseDisplayUnits: composer.settings.glucoseDisplayUnits)
        } catch {
            return SimpleEntry(looper: nil, currentGlucoseSample: nil, lastGlucoseChange: 0, date: Date(), entryIndex: 0, isLastEntry: true, glucoseDisplayUnits: composer.settings.glucoseDisplayUnits)
        }
    }
     */
    
    func getLastGlucoseChange(composer: ServiceComposer, samples: [NewGlucoseSample]) -> Double? {
        guard samples.count > 1 else {
            return nil
        }
        let lastGlucoseValue = samples[samples.count - 1].presentableUserValue(displayUnits: composer.settings.glucoseDisplayUnits)
        let priorGlucoseValue = samples[samples.count - 2].presentableUserValue(displayUnits: composer.settings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
}
