//
//  Action.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/25/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation

public enum Action: Codable, Equatable {
    case temporaryScheduleOverride(OverrideAction)
    case cancelTemporaryOverride(OverrideCancelAction)
    case bolusEntry(BolusAction)
    case carbsEntry(CarbAction)
    case autobolus(AutobolusAction)
    case closedLoop(ClosedLoopAction)
    
    public var actionName: String {
        switch self {
        case .carbsEntry:
            return "Carbs"
        case .bolusEntry:
            return "Bolus"
        case .cancelTemporaryOverride:
            return "Override Cancel"
        case .temporaryScheduleOverride:
            return "Override"
        case .closedLoop:
            return "Closed Loop"
        case .autobolus:
            return "Autobolus"
        }
    }
    
    public var actionDetails: String {
        switch self {
        case .carbsEntry(let carbAction):
            return "\(carbAction.amountInGrams)g"
        case .bolusEntry(let bolusAction):
            return "\(bolusAction.amountInUnits)u"
        case .cancelTemporaryOverride:
            return ""
        case .temporaryScheduleOverride(let overrideAction):
            return "\(overrideAction.name)"
        case .autobolus(let autobolusAction):
            return autobolusAction.active ? "Activate" : "Deactivate"
        case .closedLoop(let closeLoopAction):
            return closeLoopAction.active ? "Activate" : "Deactivate"
        }
    }
}
