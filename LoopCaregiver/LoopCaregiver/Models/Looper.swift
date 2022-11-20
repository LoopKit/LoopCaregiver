//
//  Looper.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import NightscoutClient
import SwiftUI

class Looper: ObservableObject, Hashable, OTPManagerDelegate {
    
    @Published var otpCode: String
    @Published var nightscoutDataSource: NightscoutDataSource
    
    var name: String
    var nightscoutURL: String
    var apiSecret: String
    var otpURL: String
    var lastSelectedDate: Date
    var nightscoutService: NightscoutService //TODO hide this in nightscoutDataSource
    
    private var otpManager: OTPManager
    
    init(name: String, nightscoutURL: String, apiSecret: String, otpURL: String, lastSelectedDate: Date) {
        self.name = name
        self.nightscoutURL = nightscoutURL
        self.apiSecret = apiSecret
        self.otpURL = otpURL
        self.lastSelectedDate = lastSelectedDate
        self.nightscoutService = NightscoutService(baseURL: URL(string: nightscoutURL)!, secret: apiSecret, nowDateProvider: {Date()})
        self.nightscoutDataSource = NightscoutDataSource(nightscoutService: nightscoutService)
        self.otpManager = OTPManager(optURL: otpURL)
        self.otpCode = self.otpManager.otpCode
        self.otpManager.delegate = self
    }
    
    //MARK: OTPManagerDelegate
    
    func otpDidUpdate(manager: OTPManager, otpCode: String) {
        self.otpCode = otpCode
    }
    
    //MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name + nightscoutURL + apiSecret + otpURL)
    }
    
    
    //MARK: Equatable
    
    static func == (lhs: Looper, rhs: Looper) -> Bool {
        return lhs.name == rhs.name &&
        lhs.nightscoutURL == rhs.nightscoutURL &&
        lhs.apiSecret == rhs.apiSecret &&
        lhs.otpURL == rhs.otpURL
    }
    
    deinit {
        do {
            try self.nightscoutDataSource.shutdown()
        } catch {
            print("Shutdown error: \(error)")
        }

    }
    
}

extension Looper: Identifiable {
    var id: String {
        return String([name, nightscoutURL, apiSecret, otpURL].joined(separator: "-"))
    }
}
