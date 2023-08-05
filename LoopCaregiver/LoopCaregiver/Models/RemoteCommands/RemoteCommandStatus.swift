//
//  RemoteCommandStatus.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 3/19/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation

public struct RemoteCommandStatus: Codable, Equatable {
    
    public let state: RemoteComandState
    public let message: String
    
    public enum RemoteComandState: String, Codable {
        case Pending
        case InProgress
        case Success
        case Error
        
        var title: String {
            switch self {
            case .Pending:
                return "Pending"
            case .InProgress:
                return "In-Progress"
            case .Success:
                return "Success"
            case .Error:
                return "Error"
            }
        }
    }
    
    public enum RemoteCommandStatusError: LocalizedError {
        case parseError
    }
    
    public init(state: RemoteCommandStatus.RemoteComandState, message: String) {
        self.state = state
        self.message = message
    }
    
}
