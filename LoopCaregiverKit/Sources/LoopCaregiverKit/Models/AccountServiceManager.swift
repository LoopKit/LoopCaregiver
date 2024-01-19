//
//  AccountServiceManager.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import LoopKit

public class AccountServiceManager: ObservableObject, AccountServiceDelegate, AccountService {
    
    public typealias RemoteServicesProviderFactory = (_: Looper, _: CaregiverSettings) -> any RemoteDataServiceProvider
    public weak var delegate: AccountServiceDelegate?
    
    //Account Service
    @Published public var loopers: [Looper] = []
    @Published public var selectedLooper: Looper? = nil
    private var accountService: AccountService
    private let remoteServicesProviderFactory: RemoteServicesProviderFactory
    
    public init(accountService: AccountService, remoteServicesProviderFactory: RemoteServicesProviderFactory? = nil){
        self.accountService = accountService
        
        if let remoteServicesProviderFactory {
            self.remoteServicesProviderFactory = remoteServicesProviderFactory
        } else {
            self.remoteServicesProviderFactory = { (looper, settings) in
                return NightscoutDataSource(looper: looper, settings: settings)
            }
        }
        
        refreshSync()
        accountService.delegate = self
    }
        
    
    //MARK: Account Service
    
    public func getLoopers() throws -> [Looper] {
        return try accountService.getLoopers()
    }
    
    public func updateActiveLoopUser(_ looper: Looper) throws {
        try accountService.updateActiveLoopUser(looper)
    }
    
    public func addLooper(_ looper: Looper) throws {
        try accountService.addLooper(looper)
    }
    
    public func removeLooper(_ looper: Looper) throws {
        try accountService.removeLooper(looper)
    }
    
    public func removeAllLoopers() throws {
        for looper in loopers {
            try removeLooper(looper)
        }
    }
    
    
    //MARK:
    
    public func createLooperService(looper: Looper, settings: CaregiverSettings) -> LooperService {
        let remoteDataSource = remoteServicesProviderFactory(looper, settings)
        let manager = RemoteDataServiceManager(remoteDataProvider: remoteDataSource)
        manager.monitorForUpdates()
        return LooperService(looper: looper,
                             accountService: self,
                             remoteDataSource: manager,
                             settings: settings
        )
    }
    
    func refresh(){
        //TODO: This dispatch async is to prevent SwiftUI triggering this causes recursive updates.
        DispatchQueue.main.async {
            self.refreshSync()
        }
    }
    
    func refreshSync(){
        do {
            self.loopers = try accountService.getLoopers()
                .sorted(by: {$0.name < $1.name})
            self.selectedLooper = self.loopers.sorted(by: {$0.lastSelectedDate < $1.lastSelectedDate}).last
        } catch {
            self.selectedLooper = nil
            self.loopers = []
            print("Error Fetching Keychain \(error)")
        }
    }
    
    
    //MARK: PersistenceControllerDelegate
    
    public func accountServiceDataUpdated(_ service: AccountService) {
        self.refresh()
    }
    
}

public extension AccountServiceManager {
    
    //For debugging, this uses a local file on your mac to populate a user on an iPhone Simulator
    func simulatorCredentials() -> NightscoutCredentials? {
        
        //The NSSearchPathForDirectoriesInDomains only returns the Desktop path in the
        //app container, not the mac. So this must be hardcoded to your local file.
        let jsonFileURL = URL(filePath: "/Users/bill/Desktop/Loop/loopcaregiver-test.json")
        
        guard FileManager.default.fileExists(atPath: jsonFileURL.path) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: jsonFileURL) else {
            return nil
        }
        
        guard let credentials = try? JSONDecoder().decode(NightscoutCredentials.self, from: data) else {
            return nil
        }
        
        return NightscoutCredentials(url: credentials.url.absoluteURL, secretKey: credentials.secretKey, otpURL: credentials.otpURL)
    }
}
