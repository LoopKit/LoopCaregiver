//
//  LooperService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/24/22.
//

import Foundation

public class LooperService: ObservableObject, Hashable {
    
    public let looper: Looper
    public let accountService: AccountServiceManager
    public var remoteDataSource: RemoteDataServiceManager
    public let settings: CaregiverSettings
    
    public init(looper: Looper, accountService: AccountServiceManager, remoteDataSource: RemoteDataServiceManager, settings: CaregiverSettings) {
        self.looper = looper
        self.accountService = accountService
        self.remoteDataSource = remoteDataSource
        self.settings = settings
    }
    
    //Hashable
    
    public static func == (lhs: LooperService, rhs: LooperService) -> Bool {
        lhs.looper.id == rhs.looper.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(looper.id)
    }
}
