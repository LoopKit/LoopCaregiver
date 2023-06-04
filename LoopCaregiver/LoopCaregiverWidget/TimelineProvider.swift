//
//  TimelineProvider.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//  Copyright © 2023 Bill Gestrich. All rights reserved.
//

import WidgetKit
import CoreData
import LoopKit

struct TimelineProvider: IntentTimelineProvider {
    
    //MARK: Caregiver Services
    
    var accountServiceManager: AccountServiceManager {
        return AccountServiceManager(accountService: CoreDataAccountService(inMemory: false))
    }
    
    var remoteDataSource: RemoteDataServiceProvider? {
        guard let selectedLooper = accountServiceManager.selectedLooper else {
            return nil
        }
        return NightscoutDataSource(looper: selectedLooper, settings: caregiverSettings)
    }
    
    var caregiverSettings: CaregiverSettings {
        return CaregiverSettings()
    }
    
    func getEntry(configuration: ConfigurationIntent, completion: @escaping (SimpleEntry) -> Void ) {
        Task {
            
            guard let nightscoutDataSource = remoteDataSource else {
                completion(SimpleEntry(looper: nil, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, configuration: configuration))
                return
            }
            
            let sortedSamples = try await nightscoutDataSource.fetchGlucoseSamples().sorted(by: {$0.date < $1.date})
            let latestGlucoseSample = sortedSamples.last
            let glucoseChange = getLastGlucoseChange(samples: sortedSamples)
            completion(SimpleEntry(looper: accountServiceManager.selectedLooper, currentGlucoseSample: latestGlucoseSample, lastGlucoseChange: glucoseChange, date: Date(), entryIndex: 0, configuration: configuration))
        }
    }
    
    func getLastGlucoseChange(samples: [NewGlucoseSample]) -> Double? {
        guard samples.count > 1 else {
            return nil
        }
        let lastGlucoseValue = samples[samples.count - 1].presentableUserValue(displayUnits: caregiverSettings.glucoseDisplayUnits)
        let priorGlucoseValue = samples[samples.count - 2].presentableUserValue(displayUnits: caregiverSettings.glucoseDisplayUnits)
        return lastGlucoseValue - priorGlucoseValue
    }
        
    
    //MARK: IntentTimelineProvider
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(looper: accountServiceManager.selectedLooper, currentGlucoseSample: nil, lastGlucoseChange: nil, date: Date(), entryIndex: 0, configuration: ConfigurationIntent())
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
            
            for index in 0..<60 {
                let futureEntry = SimpleEntry(looper: entry.looper,
                                              currentGlucoseSample: entry.currentGlucoseSample,
                                              lastGlucoseChange: entry.lastGlucoseChange,
                                              date: nowDate.addingTimeInterval(60 * TimeInterval(index)),
                                              entryIndex: index,
                                              configuration: configuration)
                entries.append(futureEntry)
            }
            let timeline = Timeline(entries: entries, policy: .after(nextRequestDate))
            completion(timeline)
        }
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        //The docs suggest this is inactive on iOS but check for WatchOS when supported
        return [
            IntentRecommendation(intent: ConfigurationIntent(), description: "Caregiver")
        ]
    }
}
