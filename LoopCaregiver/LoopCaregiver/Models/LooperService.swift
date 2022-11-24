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
    var remoteDataSource: RemoteDataServiceManager
    
    init(looper: Looper, accountService: AccountServiceManager, remoteDataSource: RemoteDataServiceManager) {
        self.looper = looper
        self.accountService = accountService
        self.remoteDataSource = remoteDataSource
    }
    
    deinit {
        do {
            try self.remoteDataSource.shutdown()
        } catch {
            print("Shutdown error: \(error)")
        }

    }
}
