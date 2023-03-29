//
//  COBStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

extension COBStatus: Equatable {
    public static func == (lhs: COBStatus, rhs: COBStatus) -> Bool {
        return lhs.timestamp == rhs.timestamp
        && lhs.cob == rhs.cob
    }
}
