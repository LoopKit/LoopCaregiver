//
//  Bundle+Extensions.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 6/2/23.
//

import Foundation

extension Bundle {
    
    var bundleDisplayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
    var appGroupSuiteName: String? {
        return object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
    }
}

