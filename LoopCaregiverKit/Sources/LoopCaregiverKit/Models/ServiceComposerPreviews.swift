//
//  ServiceComposerPreviews.swift
//  
//
//  Created by Bill Gestrich on 1/16/24.
//

import Foundation

public class ServiceComposerPreviews: ServiceComposer {
    public let settings: CaregiverSettings
    public let accountServiceManager: AccountServiceManager
    public var watchSession: WatchSession
    public var watchService: WatchService
    
    public init() {
        let containerFactory = InMemoryPersistentContainerFactory()
        let userDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)!
        self.settings = CaregiverSettings(userDefaults: userDefaults, appGroupsSupported: true)
        self.accountServiceManager = AccountServiceManager(accountService: CoreDataAccountService(containerFactory: containerFactory), remoteServicesProviderFactory: { (_, _) in RemoteDataServiceProviderSimulator()})
        self.watchService = WatchService(accountService: self.accountServiceManager)
        self.watchSession = self.watchService.watchSession
        self.addTestLooper()
    }
    
    func addTestLooper() {
        let nsCredentials = NightscoutCredentials(url: URL(string: "https://wwww.sample.com")!, secretKey: "12345", otpURL: "12345")
        let looper = Looper(identifier: UUID(), name: "Liz", nightscoutCredentials: nsCredentials, lastSelectedDate: Date())
        try! self.accountServiceManager.addLooper(looper)
        self.accountServiceManager.selectedLooper = looper
    }
}
