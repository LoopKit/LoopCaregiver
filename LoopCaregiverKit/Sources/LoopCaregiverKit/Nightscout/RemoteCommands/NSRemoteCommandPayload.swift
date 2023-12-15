//
//  NSRemoteCommandPayload.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/27/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import NightscoutKit

extension NSRemoteCommandPayload {
    
    public func toRemoteCommand() throws -> RemoteCommand {
        
        guard let id = _id else {
            throw RemoteCommandPayloadError.missingID
        }
        
        return RemoteCommand(id: id, action: toRemoteAction(), status: status.toStatus(), createdDate: createdDate)
    }
    
    public func toRemoteAction() -> Action {
        switch action {
        case .bolus(let amountInUnits):
            return .bolusEntry(BolusAction(amountInUnits: amountInUnits))
        case .carbs(let amountInGrams, let absorptionTime, let startDate):
            return .carbsEntry(CarbAction(amountInGrams: amountInGrams, absorptionTime: absorptionTime, startDate: startDate))
        case .override(let name, let durationTime, let remoteAddress):
            return .temporaryScheduleOverride(OverrideAction(name: name, durationTime: durationTime, remoteAddress: remoteAddress))
        case .cancelOverride(let remoteAddress):
            return .cancelTemporaryOverride(OverrideCancelAction(remoteAddress: remoteAddress))
        case .autobolus(let active):
            return .autobolus(AutobolusAction(active: active))
        case .closedLoop(let active):
            return .closedLoop(ClosedLoopAction(active: active))
        }
    }
}

extension NSRemoteCommandStatus {
    func toStatus() -> RemoteCommandStatus {
        let commandState: RemoteCommandStatus.RemoteComandState
        switch self.state {
        case .Pending:
            commandState = RemoteCommandStatus.RemoteComandState.Pending
        case .InProgress:
            commandState = RemoteCommandStatus.RemoteComandState.InProgress
        case .Success:
            commandState = RemoteCommandStatus.RemoteComandState.Success
        case .Error:
            let error = RemoteCommandStatus.RemoteCommandStatusError(message: message)
            commandState = RemoteCommandStatus.RemoteComandState.Error(error)
        }
        return RemoteCommandStatus(state: commandState, message: message)
    }
}

enum RemoteCommandPayloadError: LocalizedError {
    case missingID
    
    var errorDescription: String? {
        switch self {
        case .missingID:
            return "Missing ID"
        }
    }
}
