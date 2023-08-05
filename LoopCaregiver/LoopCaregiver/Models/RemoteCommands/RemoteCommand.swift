//
//  RemoteCommand.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 2/25/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation

struct RemoteCommand: Equatable {
    let id: String
    let action: Action
    let status: RemoteCommandStatus
    let createdDate: Date
}
