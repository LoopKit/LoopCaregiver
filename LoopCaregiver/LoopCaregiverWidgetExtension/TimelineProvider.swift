//
//  TimelineProvider.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//  Copyright © 2023 Bill Gestrich. All rights reserved.
//

import CoreData
import Intents
import LoopCaregiverKit
import LoopKit
import WidgetKit

struct TimelineProvider: IntentTimelineProvider {
    
    //MARK: Caregiver Services
    
    let composer = ServiceComposerProduction()
    
    var accountServiceManager: AccountServiceManager {
        return AccountServiceManager(accountService: composer.accountServiceManager)
    }
    
    func remoteDataSource(looper: Looper) -> RemoteDataServiceProvider {
        return NightscoutDataSource(looper: looper, settings: composer.settings)
    }
    
    func getEntry(configuration: ConfigurationIntent, completion: @escaping (SimpleEntry) -> Void ) {
        Task {
            
            var looper: Looper
            if let configurationLooper = getLooper(configuration: configuration) {
                looper = configurationLooper
            } else if let selectedLooper = accountServiceManager.selectedLooper {
                looper = selectedLooper
            } else {
                completion(SimpleEntry(looper: nil, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true))
                return
            }
            
            let nightscoutDataSource = remoteDataSource(looper: looper)
            let sortedSamples = try await nightscoutDataSource.fetchRecentGlucoseSamples().sorted(by: {$0.date < $1.date})
            let latestGlucoseSample = sortedSamples.last
            let glucoseChange = getLastGlucoseChange(samples: sortedSamples)
            
            completion(SimpleEntry(looper: looper, currentGlucoseSample: latestGlucoseSample, lastGlucoseChange: glucoseChange, date: Date(), entryIndex: 0, isLastEntry: true))
        }
    }
    
    func getLooper(configuration: ConfigurationIntent) -> Looper? {
        guard let configurationLooper = configuration.looper else {
            return nil
        }
        
        do {
            return try accountServiceManager.getLoopers().first(where: {$0.id == configurationLooper.identifier})
        } catch {
            print("Error \(error)")
            return nil
        }
    }
    
    func getLastGlucoseChange(samples: [NewGlucoseSample]) -> Double? {
        guard samples.count > 1 else {
            return nil
        }
        let lastGlucoseValue = samples[samples.count - 1].presentableUserValue(displayUnits: composer.settings.glucoseDisplayUnits)
        let priorGlucoseValue = samples[samples.count - 2].presentableUserValue(displayUnits: composer.settings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
        
    
    //MARK: IntentTimelineProvider
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(looper: accountServiceManager.selectedLooper, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, isLastEntry: true)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        getEntry(configuration: configuration) { entry in
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        getEntry(configuration: configuration) { entry in
            
            var entries = [SimpleEntry]()
            let nowDate = Date()
            
            var nextRequestDate: Date = nowDate.addingTimeInterval(60*5) //Default interval
            if let nextExpectedGlucoseDate = entry.nextExpectedGlucoseDate(), nextExpectedGlucoseDate > nowDate {
                nextRequestDate = nextExpectedGlucoseDate.addingTimeInterval(60*1) //Extra minute to allow time for upload.
            }
            
            let indexCount = 60
            for index in 0..<indexCount {
                let isLastEntry = index == (indexCount - 1)
                let futureEntry = SimpleEntry(looper: entry.looper,
                                              currentGlucoseSample: entry.currentGlucoseSample,
                                              lastGlucoseChange: entry.lastGlucoseChange,
                                              date: nowDate.addingTimeInterval(60 * TimeInterval(index)),
                                              entryIndex: index,
                                              isLastEntry: isLastEntry)
                entries.append(futureEntry)
            }
            let timeline = Timeline(entries: entries, policy: .after(nextRequestDate))
            completion(timeline)
        }
    }
}
