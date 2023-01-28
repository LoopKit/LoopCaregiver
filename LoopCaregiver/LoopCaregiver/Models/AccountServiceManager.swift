//
//  AccountServiceManager.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import LoopKit

class AccountServiceManager: ObservableObject, AccountServiceDelegate, AccountService {
    
    weak var delegate: AccountServiceDelegate?
    
    //Account Service
    @Published var loopers: [Looper] = []
    @Published var selectedLooper: Looper? = nil
    private var accountService: AccountService
    
    init(accountService: AccountService){
        self.accountService = accountService
        refreshSync()
        accountService.delegate = self
    }
        
    
    //MARK: Account Service
    
    func getLoopers() throws -> [Looper] {
        return try accountService.getLoopers()
    }
    
    func updateActiveLoopUser(_ looper: Looper) throws {
        try accountService.updateActiveLoopUser(looper)
    }
    
    func addLooper(_ looper: Looper) throws {
        try accountService.addLooper(looper)
    }
    
    func removeLooper(_ looper: Looper) throws {
        try accountService.removeLooper(looper)
    }
    
    func removeAllLoopers() throws {
        for looper in loopers {
            try removeLooper(looper)
        }
    }
    
    
    //MARK:
    
    func createLooperService(looper: Looper, settings: CaregiverSettings) -> LooperService {
        let remoteDataSource = RemoteDataServiceManager(remoteDataProvider: NightscoutDataSource(looper: looper, settings: settings))
        return LooperService(looper: looper,
                                              accountService: self,
                             remoteDataSource: remoteDataSource,
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
    
    func accountServiceDataUpdated(_ service: AccountService) {
        self.refresh()
    }
    
}

extension AccountServiceManager {
    func simulatorCredentials() -> NightscoutCredentials? {
        
        let fileURL = URL(filePath: "/Users/bill/Desktop/Loop/loopcaregiver-test.json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try! Data(contentsOf: fileURL)
        let credentials = try! JSONDecoder().decode(NightscoutCredentials.self, from: data)
        return NightscoutCredentials(url: credentials.url.absoluteURL, secretKey: credentials.secretKey, otpURL: credentials.otpURL)
    }
}
