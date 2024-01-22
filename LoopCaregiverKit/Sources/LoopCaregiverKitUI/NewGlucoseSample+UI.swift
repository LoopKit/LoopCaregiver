//
//  NewGlucoseSample+UI.swift
//
//
//  Created by Bill Gestrich on 1/22/24.
//

import Foundation
import LoopKit

public extension NewGlucoseSample {
    func arrowImageName() -> String {
        
        guard let trend = self.trend else {
            return "questionmark"
        }
        
        switch trend {
            
        case .up:
            return "arrow.up.forward"
        case .upUp:
            return "arrow.up"
        case .upUpUp:
            return "arrow.up"
        case .flat:
            return "arrow.right"
        case .down:
            return "arrow.down.forward"
        case .downDown:
            return "arrow.down"
        case .downDownDown:
            return "arrow.down"
        }
    }
}

