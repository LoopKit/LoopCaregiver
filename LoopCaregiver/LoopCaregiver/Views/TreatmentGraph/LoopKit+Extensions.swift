//
//  LoopKit+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/25/22.
//

import Foundation
import LoopKit

extension NewGlucoseSample {
    func graphItem() -> GraphItem {
        return GraphItem(type: .egv, value: intValue(), displayTime: date)
    }
    
    func intValue() -> Int {
        return Int(quantity.doubleValue(for: .milligramsPerDeciliter)) //TODO: Crash Potential
    }
}
