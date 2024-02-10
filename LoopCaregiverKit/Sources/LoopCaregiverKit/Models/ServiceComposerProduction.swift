//
//  ServiceComposerProduction.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/15/23.
//

import Foundation

public class ServiceComposerProduction: ServiceComposer {
    public let settings: CaregiverSettings
    public let accountServiceManager: AccountServiceManager
    public let watchSession: WatchSession
    public let watchService: WatchService
    
    public init() {
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

        self.watchService = WatchService(accountService: self.accountServiceManager)
        self.watchSession = self.watchService.watchSession
    }
}
