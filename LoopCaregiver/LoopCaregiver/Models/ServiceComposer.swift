//
//  ServiceComposer.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/15/23.
//

import Foundation

class ServiceComposer {
    let settings: CaregiverSettings
    let accountServiceManager: AccountServiceManager
    
    init() {
        let userDefaults: UserDefaults
        let containerFactory: PersistentContainerFactory
        let appGroupsSupported = Self.appGroupsSupported
        if appGroupsSupported {
            userDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)!
            containerFactory = AppGroupPersisentContainerFactory()
        } else {
            userDefaults = UserDefaults.standard
            containerFactory = NoAppGroupsPersistentContainerFactory()
        }
        
        self.settings = CaregiverSettings(userDefaults: userDefaults, appGroupsSupported: appGroupsSupported)
        self.accountServiceManager = AccountServiceManager(accountService: CoreDataAccountService(containerFactory: containerFactory))
    }
    
    static var appGroupsSupported: Bool {
        return false
    }
}
