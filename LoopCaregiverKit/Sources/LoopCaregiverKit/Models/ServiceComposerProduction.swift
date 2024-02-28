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
    public let watchService: WatchService
    public let deepLinkHandler: DeepLinkHandler
    
    public init() {
        let userDefaults: UserDefaults
        let containerFactory: PersistentContainerFactory
        var appGroupsSupported = false

        if let appGroupName = Bundle.main.appGroupSuiteName, let _ = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) {
            appGroupsSupported = true
            userDefaults = UserDefaults(suiteName: appGroupName)!
            containerFactory = AppGroupPersisentContainerFactory(appGroupName: appGroupName)
        } else {
            userDefaults = UserDefaults.standard
            containerFactory = NoAppGroupsPersistentContainerFactory()
        }
        
        self.settings = CaregiverSettings(userDefaults: userDefaults, appGroupsSupported: appGroupsSupported)
        self.accountServiceManager = AccountServiceManager(accountService: CoreDataAccountService(containerFactory: containerFactory))

        self.watchService = WatchService(accountService: self.accountServiceManager)
        
        #if os(iOS)
        self.deepLinkHandler = DeepLinkHandlerPhone(accountService: accountServiceManager, settings: settings, watchService: watchService)
        #elseif os(watchOS)
        self.deepLinkHandler = DeepLinkHandlerWatch(accountService: accountServiceManager, settings: settings, watchService: watchService)
        #else
        self.deepLinkHandler = DeepLinkHandlerPhone(accountService: accountServiceManager, settings: settings, watchService: watchService)
        fatalError("Unsupported platform")
        #endif

    }
}
