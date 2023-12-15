//
//  ProfileSet.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/7/23.
//

import Foundation
import NightscoutKit

public extension ProfileSet {
    func getDefaultProfile() -> Profile? { //get* prefixed because `defaultProfile` already defined as a String on ProfileSet
        return store["Default"]
    }
}

extension ProfileSet: Equatable {
    public static func == (lhs: ProfileSet, rhs: ProfileSet) -> Bool {
        return lhs.startDate == rhs.startDate
    }
}
