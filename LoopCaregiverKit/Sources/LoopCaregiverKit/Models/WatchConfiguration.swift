//
//  WatchConfiguration.swift
//
//
//  Created by Bill Gestrich on 1/27/24.
//

import Foundation

public struct WatchConfiguration: Codable {
    
    public let loopers: [Looper]
    public let sentDate: Date
    
    public init(loopers: [Looper]) {
        self.loopers = loopers
        self.sentDate = Date()
    }
}
