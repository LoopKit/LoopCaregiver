//
//  Date+Utils.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 2/12/23.
//

import Foundation

extension Date: RawRepresentable {
    public var rawValue: String {
        self.timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        guard let doubleValue = Double(rawValue) else {
            return nil
        }
        self = Date(timeIntervalSinceReferenceDate: doubleValue)
    }
}
