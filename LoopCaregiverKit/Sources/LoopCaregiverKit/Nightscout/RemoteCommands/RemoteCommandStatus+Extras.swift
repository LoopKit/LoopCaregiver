//
//  RemoteCommandStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/31/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import LoopKit
import NightscoutKit

extension RemoteCommandStatus {
    func toNSRemoteCommandStatus() -> NSRemoteCommandStatus {
        return NSRemoteCommandStatus(state: state.toNSRemoteCommandState(), message: message)
    }
}

extension RemoteCommandStatus.RemoteComandState {
    func toNSRemoteCommandState() -> NSRemoteCommandStatus.NSRemoteComandState {
        switch self {
        case .Error:
            return .Error
        case .Success:
            return .Success
        case .InProgress:
            return .InProgress
        case .Pending:
            return .Pending
        }
    }
}
