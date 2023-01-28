//
//  LooperService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation

class LooperService: ObservableObject, Hashable {
    
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
    
    //Hashable
    
    static func == (lhs: LooperService, rhs: LooperService) -> Bool {
        lhs.looper.id == rhs.looper.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(looper.id)
    }
}
