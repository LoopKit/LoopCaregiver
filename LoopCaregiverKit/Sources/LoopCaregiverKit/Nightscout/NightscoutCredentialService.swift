//
//  NightscoutCredentialService.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/21/22.
//

import Foundation

public class NightscoutCredentialService: ObservableObject, Hashable, OTPManagerDelegate {

    @Published public var otpCode: String
    
    public let credentials: NightscoutCredentials
    public let otpManager: OTPManager
    
    
    public init(credentials: NightscoutCredentials) {
        self.credentials = credentials
        self.otpManager = OTPManager(optURL: credentials.otpURL)
        self.otpCode = otpManager.otpCode
        self.otpManager.delegate = self
    }
    
    
    //MARK: OTPManagerDelegate
    
    public func otpDidUpdate(manager: OTPManager, otpCode: String) {
        self.otpCode = otpCode
    }
    
    
    //MARK: Equatable
    
    public static func == (lhs: NightscoutCredentialService, rhs: NightscoutCredentialService) -> Bool {
        return lhs.credentials == rhs.credentials
    }
    
    //MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentials)
    }
    
}
