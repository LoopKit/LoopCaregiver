//
//  LooperService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation

class LooperService: ObservableObject {
    
    let looper: Looper
    let accountService: AccountServiceManager
    var nightscoutDataSource: NightscoutDataSource
    
    init(looper: Looper, accountService: AccountServiceManager, nightscoutDataSource: NightscoutDataSource) {
        self.looper = looper
        self.accountService = accountService
        self.nightscoutDataSource = nightscoutDataSource
    }
    
    deinit {
        do {
            try self.nightscoutDataSource.shutdown()
        } catch {
            print("Shutdown error: \(error)")
        }

    }
}
