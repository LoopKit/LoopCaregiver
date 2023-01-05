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
    let settings: CaregiverSettings
    
    init(looper: Looper, accountService: AccountServiceManager, remoteDataSource: RemoteDataServiceManager, settings: CaregiverSettings) {
        self.looper = looper
        self.accountService = accountService
        self.remoteDataSource = remoteDataSource
        self.settings = settings
    }
}
