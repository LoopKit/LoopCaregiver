//
//  LooperService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation

class LooperService {
    
    let looper: Looper
    let accountService: AccountServiceManager
    
    internal init(looper: Looper, accountService: AccountServiceManager) {
        self.looper = looper
        self.accountService = accountService
    }
}
