//
//  AccountService.swift
//  Test
//
//  Created by Bill Gestrich on 11/18/22.
//

import Foundation

protocol AccountService {
    var delegate: AccountServiceDelegate? {get set}
    func addLooper(_ looper: Looper) throws
    func fetchLooperCD(name: String) throws -> LooperCD?
    func updateLooperLastSelectedDate(looper: Looper, _ date: Date) throws -> Looper
    func getLoopers() throws -> [Looper]
    func removeLooper(_ looper: Looper) throws
}

protocol AccountServiceDelegate: AnyObject {
    func accountServiceDataUpdated(_ service:AccountService)
}
