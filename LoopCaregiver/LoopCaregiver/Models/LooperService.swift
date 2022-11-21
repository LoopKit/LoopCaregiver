//
//  LooperService.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import NightscoutClient
import LoopKit

class LooperService: ObservableObject, PersistenceControllerDelegate {
    
    @Published var loopers: [Looper] = []
    @Published var selectedLooper: Looper? = nil
    
    private var coreDataService: LooperCoreDataService
    
    init(coreDataService: LooperCoreDataService){
        self.coreDataService = coreDataService
        refreshSync()
        LooperCoreDataService.shared.delegate = self
    }
        
    func addLooper(_ looper: Looper) throws {
        try coreDataService.addLooper(looper)
    }
    
    func removeLooper(_ looper: Looper) throws {
        try coreDataService.removeLooper(looper)
    }
    
    func updateActiveLoopUser(_ looper: Looper) throws {
        let updatedLooper = Looper(name: looper.name, nightscoutCredentials: looper.nightscoutCredentials, lastSelectedDate: Date())
        try removeLooper(looper)
        try addLooper(updatedLooper)
    }
    
    func removeAllLoopers() throws {
        for looper in loopers {
            try removeLooper(looper)
        }
    }
    
    func refresh(){
        //TODO: This dispatch async is to prevent SwiftUI triggering this causes recursive updates.
        DispatchQueue.main.async {
            self.refreshSync()
        }
    }
    
    func refreshSync(){
        do {
            self.loopers = try coreDataService.getLoopers()
                .sorted(by: {$0.name < $1.name})
            self.selectedLooper = self.loopers.sorted(by: {$0.lastSelectedDate < $1.lastSelectedDate}).last
        } catch {
            self.selectedLooper = nil
            self.loopers = []
            print("Error Fetching Keychain \(error)")
        }
    }
    
    
    //MARK: PersistenceControllerDelegate
    
    func persistentServiceDataUpdated(_ service: LooperCoreDataService) {
        self.refresh()
    }
    
}

extension LooperService {
    func simulatorCredentials() -> NightscoutCredentials? {
        
        let fileURL = URL(filePath: "/Users/bill/Desktop/Loop/loopcaregiver-prod.json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try! Data(contentsOf: fileURL)
        let credentials = try! JSONDecoder().decode(NightscoutCredentials.self, from: data)
        return NightscoutCredentials(url: credentials.url.absoluteURL, secretKey: credentials.secretKey, otpURL: credentials.otpURL)
    }
}
