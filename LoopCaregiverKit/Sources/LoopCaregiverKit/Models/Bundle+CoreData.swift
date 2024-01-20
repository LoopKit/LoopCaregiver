//
//  Bundle+CoreData.swift
//
//
//  Created by Bill Gestrich on 12/15/23.
//

import Foundation

extension Bundle {
    public static var coreDataModelURL: URL {
        return Self.module.url(forResource: "LoopCaregiver", withExtension: "momd")!
    }
}
