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
    
    init(){
        refreshSync()
        PersistenceController.shared.delegate = self
    }
        
    func addLooper(_ looper: Looper) throws {
        PersistenceController.shared.addLooper(looper)
    }
    
    func removeLooper(_ looper: Looper) throws {
        try PersistenceController.shared.removeLooper(looper)
    }
    
    func updateActiveLoopUser(_ looper: Looper) throws {
        let updatedLooper = Looper(name: looper.name, nightscoutURL: looper.nightscoutURL, apiSecret: looper.apiSecret, otpURL: looper.otpURL, lastSelectedDate: Date())
        try removeLooper(looper)
        try addLooper(updatedLooper)
    }
    
    func removeAllLoopers() throws {
        for looper in loopers {
            try removeLooper(looper)
        }
    }
    
    func refresh(){
        DispatchQueue.main.async {
            self.refreshSync()
        }
    }
    
    func refreshSync(){
        do {
            self.loopers = try PersistenceController.shared.getLoopers()
                .sorted(by: {$0.name < $1.name})
            self.selectedLooper = self.loopers.sorted(by: {$0.lastSelectedDate < $1.lastSelectedDate}).last
        } catch {
            self.selectedLooper = nil
            self.loopers = []
            print("Error Fetching Keychain \(error)")
        }
    }
    
    
    //MARK: PersistenceControllerDelegate
    
    func persistentServiceDataUpdated(_ service: PersistenceController) {
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


struct NightscoutCredentials: Codable {
    let url: URL
    let secretKey: String
    let otpURL: String
}


//TODO: These extensions belong in the containing swift package

extension NightscoutEGV: Equatable {
    public static func == (lhs: NightscoutEGV, rhs: NightscoutEGV) -> Bool {
        return lhs.displayTime == rhs.displayTime &&
        lhs.systemTime == rhs.displayTime &&
        lhs.value == rhs.value
    }
}

extension NightscoutEGV: Identifiable {
    public var id: Date {
        return displayTime
    }
}

extension WGCarbEntry: Equatable {
    public static func == (lhs: NightscoutClient.WGCarbEntry, rhs: NightscoutClient.WGCarbEntry) -> Bool {
        return lhs.amount == rhs.amount &&
        lhs.date == rhs.date
    }
}

extension WGBolusEntry: Equatable {
    public static func == (lhs: WGBolusEntry, rhs: WGBolusEntry) -> Bool {
        return lhs.amount == rhs.amount &&
        lhs.date == rhs.date
    }
}
