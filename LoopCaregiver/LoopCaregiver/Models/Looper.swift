//
//  Looper.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import SwiftUI

class Looper: ObservableObject, Hashable {
    
    var identifier: UUID
    var name: String
    var lastSelectedDate: Date
    let nightscoutCredentials: NightscoutCredentials
    
    init(identifier: UUID, name: String, nightscoutCredentials: NightscoutCredentials, lastSelectedDate: Date) {
        self.identifier = identifier
        self.name = name
        self.lastSelectedDate = lastSelectedDate
        self.nightscoutCredentials = nightscoutCredentials
    }
    
    
    //MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    
    //MARK: Equatable
    
    static func == (lhs: Looper, rhs: Looper) -> Bool {
        //TODO: Equality should check other properties
        //See note in HUDViewModel.selectedLooper
        return lhs.identifier == rhs.identifier
    }
    
}

extension Looper: Identifiable {
    var id: String {
        return identifier.uuidString
    }
}
