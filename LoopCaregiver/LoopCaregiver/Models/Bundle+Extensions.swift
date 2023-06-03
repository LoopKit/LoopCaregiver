//
//  Bundle+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation

extension Bundle {
    var appGroupSuiteName: String {
        return object(forInfoDictionaryKey: "AppGroupIdentifier") as! String
    }
}

