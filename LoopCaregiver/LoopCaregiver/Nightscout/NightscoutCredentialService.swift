//
//  NightscoutCredentialService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/21/22.
//

import Foundation

class NightscoutCredentialService: ObservableObject, Hashable, OTPManagerDelegate {

    @Published var otpCode: String
    
    let credentials: NightscoutCredentials
    let otpManager: OTPManager
    
    
    init(credentials: NightscoutCredentials) {
        self.credentials = credentials
        self.otpManager = OTPManager(optURL: credentials.otpURL)
        self.otpCode = otpManager.otpCode
        self.otpManager.delegate = self
    }
    
    
    //MARK: OTPManagerDelegate
    
    func otpDidUpdate(manager: OTPManager, otpCode: String) {
        self.otpCode = otpCode
    }
    
    
    //MARK: Equatable
    
    static func == (lhs: NightscoutCredentialService, rhs: NightscoutCredentialService) -> Bool {
        return lhs.credentials == rhs.credentials
    }
    
    //MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(credentials)
    }
    
}
