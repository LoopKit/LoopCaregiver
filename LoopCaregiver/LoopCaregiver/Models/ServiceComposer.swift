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
        var appGroupsSupported = false

        if let appGroupName = Bundle.main.appGroupSuiteName, let _ = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) {
            appGroupsSupported = true
            userDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)!
            containerFactory = AppGroupPersisentContainerFactory(appGroupName: appGroupName)
        } else {
            userDefaults = UserDefaults.standard
            containerFactory = NoAppGroupsPersistentContainerFactory()
        }
        
        self.settings = CaregiverSettings(userDefaults: userDefaults, appGroupsSupported: appGroupsSupported)
        self.accountServiceManager = AccountServiceManager(accountService: CoreDataAccountService(containerFactory: containerFactory))
    }
}
