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
        let userDefaults = Self.createUserDefaults()
        self.settings = Self.createCaregiverSettings(userDefaults: userDefaults)
        self.accountServiceManager = Self.createAccountServiceManager()
        self.watchService = Self.createWatchService(accountServiceManager: accountServiceManager)
        self.deepLinkHandler = Self.createDeepLinkHandler(accountServiceManager: accountServiceManager, settings: settings, watchService: watchService)
    }
    
    static func createCaregiverSettings(userDefaults: UserDefaults) -> CaregiverSettings {
        let appGroupsSupported = Self.appGroupName() != nil
        return CaregiverSettings(userDefaults: userDefaults, appGroupsSupported: appGroupsSupported)
    }
    
    static func createPersistentContainerFactory() -> PersistentContainerFactory {
        if let appGroupName = appGroupName() {
            return AppGroupPersisentContainerFactory(appGroupName: appGroupName)
        } else {
            return NoAppGroupsPersistentContainerFactory()
        }
    }
    
    static func createUserDefaults() -> UserDefaults {
        if let appGroupName = appGroupName() {
            return UserDefaults(suiteName: appGroupName)!
        } else {
            return UserDefaults.standard
        }
    }
    
    static func createAccountServiceManager() -> AccountServiceManager {
        let containerFactory = Self.createPersistentContainerFactory()
        return AccountServiceManager(accountService: CoreDataAccountService(containerFactory: containerFactory))
    }
    
    static func createWatchService(accountServiceManager: AccountServiceManager) -> WatchService {
        return WatchService(accountService: accountServiceManager)
    }

    static func createDeepLinkHandler(accountServiceManager: AccountServiceManager, settings: CaregiverSettings, watchService: WatchService) -> DeepLinkHandler {
#if os(iOS)
        return DeepLinkHandlerPhone(accountService: accountServiceManager, settings: settings, watchService: watchService)
#elseif os(watchOS)
        return DeepLinkHandlerWatch(accountService: accountServiceManager, settings: settings, watchService: watchService)
#else
        return DeepLinkHandlerPhone(accountService: accountServiceManager, settings: settings, watchService: watchService)
        fatalError("Unsupported platform")
#endif
    }
    
    static func appGroupName() -> String? {
        guard let appGroupName = Bundle.main.appGroupSuiteName, let _ = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) else {
            return nil
        }
        
        return appGroupName
    }
}
