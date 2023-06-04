//
//  SimpleEntry.swift
//  LoopCaregiver
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
    let configuration: ConfigurationIntent
}
