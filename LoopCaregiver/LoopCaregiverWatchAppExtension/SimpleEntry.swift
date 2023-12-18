//
//  SimpleEntry.swift
//  LoopCaregiverWatchAppExtension
//
//  Created by Bill Gestrich on 12/18/23.
//

import Foundation
import LoopKit
import WidgetKit

struct SimpleEntry: TimelineEntry {
    let currentGlucoseSample: NewGlucoseSample?
    let lastGlucoseChange: Double?
    let date: Date
    let entryIndex: Int
    let isLastEntry: Bool
    
    func nextExpectedGlucoseDate() -> Date? {
        let secondsBetweenSamples: TimeInterval = 60 * 5
        
        guard let glucoseDate = currentGlucoseSample?.date else {
            return nil
        }
            
        return glucoseDate.addingTimeInterval(secondsBetweenSamples)
    }
}
