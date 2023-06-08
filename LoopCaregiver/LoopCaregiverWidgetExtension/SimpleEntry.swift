//
//  SimpleEntry.swift
//  LoopCaregiverWidgetExtension
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation
import WidgetKit
import LoopKit

struct SimpleEntry: TimelineEntry {
    let looper: Looper?
    let currentGlucoseSample: NewGlucoseSample?
    let lastGlucoseChange: Double?
    let date: Date
    let entryIndex: Int
    let isLastEntry: Bool
    let configuration: ConfigurationIntent
    
    func nextExpectedGlucoseDate() -> Date? {
        let secondsBetweenSamples: TimeInterval = 60 * 5
        
        guard let glucoseDate = currentGlucoseSample?.date else {
            return nil
        }
            
        return glucoseDate.addingTimeInterval(secondsBetweenSamples)
    }
}
