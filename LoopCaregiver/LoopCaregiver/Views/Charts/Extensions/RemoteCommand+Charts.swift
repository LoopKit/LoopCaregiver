//
//  RemoteCommand+Charts.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 8/6/23.
//

import Foundation
import HealthKit
import LoopCaregiverKit

extension RemoteCommand {
    func graphItem(egvValues: [GraphItem], displayUnit: HKUnit) -> GraphItem? {
        
        let treatmentDate = treatmentDate()
        let relativeEgvValue = interpolateEGVValue(egvs: egvValues, atDate: treatmentDate)
        
        switch status.state {
        case .Error:
            switch self.action {
            case .bolusEntry(let bolusEntry):
                return GraphItem(type: .bolus(bolusEntry.amountInUnits), displayTime: treatmentDate, quantity: HKQuantity(unit: displayUnit, doubleValue: relativeEgvValue), displayUnit: displayUnit, graphItemState: toGraphItemState())
            case .carbsEntry(let carbEntry):
                return GraphItem(type: .carb(Int(carbEntry.amountInGrams)), displayTime: treatmentDate, quantity: HKQuantity(unit: displayUnit, doubleValue: relativeEgvValue), displayUnit: displayUnit, graphItemState: toGraphItemState())
            default:
                return nil //Not graphing other types yet.
                //return GraphItem(type: .command(self), displayTime: createdDate, quantity: HKQuantity(unit: displayUnit, doubleValue: relativeEgvValue), displayUnit: displayUnit, graphItemState: toGraphItemState())
            }
        default:
            return nil
        }
    }
    
    func toGraphItemState() -> GraphItemState {
        switch self.status.state {
        case .Success:
            return .success
        case .Pending:
            return .pending
        case .Error(let error):
            return .error(error)
        case .InProgress:
            //TODO: Add a pending state?
            return .pending
        }
    }
    
    func treatmentDate() -> Date {
        switch action {
        case .carbsEntry(let carbAction):
            return carbAction.startDate ?? createdDate
        default:
            return createdDate
        }
    }
}
