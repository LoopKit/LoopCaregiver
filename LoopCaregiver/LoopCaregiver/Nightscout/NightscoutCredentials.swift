//
//  NightscoutCredentials.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/21/22.
//

import Foundation

struct NightscoutCredentials: Codable, Hashable {
    let url: URL
    let secretKey: String
    let otpURL: String
}
