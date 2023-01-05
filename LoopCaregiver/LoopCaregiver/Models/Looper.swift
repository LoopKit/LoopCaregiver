//
//  Looper.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import SwiftUI

class Looper: ObservableObject, Hashable {
    
    var name: String
    var lastSelectedDate: Date
    let nightscoutCredentials: NightscoutCredentials
    
    init(name: String, nightscoutCredentials: NightscoutCredentials, lastSelectedDate: Date) {
        self.name = name
        self.lastSelectedDate = lastSelectedDate
        self.nightscoutCredentials = nightscoutCredentials
    }
    
    
    //MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name) //TODO: Don't assume names are unique. Use a UUID
    }
    
    
    //MARK: Equatable
    
    static func == (lhs: Looper, rhs: Looper) -> Bool {
        return lhs.name == rhs.name //TODO: Don't assume names are unique. Use a UUID
    }
    
}

extension Looper: Identifiable {
    var id: String {
        //TODO: Don't assume names are unique. Use a UUID
        return String([name].joined(separator: "-"))
    }
}
