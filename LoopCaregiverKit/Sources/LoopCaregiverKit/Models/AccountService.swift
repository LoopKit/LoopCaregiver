//
//  AccountService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/18/22.
//

import Foundation

public protocol AccountService: AnyObject {
    var delegate: AccountServiceDelegate? {get set}
    func getLoopers() throws -> [Looper]
    func updateActiveLoopUser(_ looper: Looper) throws
    func addLooper(_ looper: Looper) throws
    func removeLooper(_ looper: Looper) throws
}

public protocol AccountServiceDelegate: AnyObject {
    func accountServiceDataUpdated(_ service:AccountService)
}
