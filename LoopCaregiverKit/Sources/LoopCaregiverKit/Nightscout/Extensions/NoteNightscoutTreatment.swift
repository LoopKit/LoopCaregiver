//
//  NoteNightscoutTreatment.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 7/31/23.
//

import Foundation
import NightscoutKit

extension NoteNightscoutTreatment: Equatable {
    public static func == (lhs: NightscoutKit.NoteNightscoutTreatment, rhs: NightscoutKit.NoteNightscoutTreatment) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
        lhs.enteredBy == rhs.enteredBy &&
        lhs.notes == rhs.notes &&
        lhs.id == rhs.id &&
        lhs.syncIdentifier == rhs.syncIdentifier &&
        lhs.insulinType == rhs.insulinType
    }
}
