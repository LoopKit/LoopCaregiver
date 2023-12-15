//
//  IOBStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

extension IOBStatus: Equatable {
    public static func == (lhs: IOBStatus, rhs: IOBStatus) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.iob == rhs.iob
    }
}
