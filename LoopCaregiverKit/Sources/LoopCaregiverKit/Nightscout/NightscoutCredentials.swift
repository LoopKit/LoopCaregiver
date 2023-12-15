//
//  NightscoutCredentials.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/21/22.
//

import Foundation

public struct NightscoutCredentials: Codable, Hashable {
    
    public let url: URL
    public let secretKey: String
    public let otpURL: String
    
    public init(url: URL, secretKey: String, otpURL: String) {
        self.url = url
        self.secretKey = secretKey
        self.otpURL = otpURL
    }
}
