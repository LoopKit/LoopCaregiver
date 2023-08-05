//
//  AutobolusAction.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 3/19/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation

public struct AutobolusAction: Codable, Equatable {
    
    public let active: Bool
    
    public init(active: Bool) {
        self.active = active
    }
}
