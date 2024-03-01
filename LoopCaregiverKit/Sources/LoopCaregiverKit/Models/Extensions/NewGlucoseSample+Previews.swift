//
//  NewGlucoseSample+Previews.swift
//
//
//  Created by Bill Gestrich on 3/1/24.
//

import Foundation
import LoopKit

public extension NewGlucoseSample {
    static func placeholder() -> NewGlucoseSample {
        return NewGlucoseSample(date: Date(), quantity: .init(unit: .milligramsPerDeciliter, doubleValue: 100.0), condition: .none, trend: .flat, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "1345")
    }
}
