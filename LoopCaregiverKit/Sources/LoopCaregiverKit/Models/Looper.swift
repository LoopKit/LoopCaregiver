//
//  Looper.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation

public class Looper: ObservableObject, Hashable, Codable {
    
    public var identifier: UUID
    public var name: String
    public var lastSelectedDate: Date
    public let nightscoutCredentials: NightscoutCredentials
    
    public init(identifier: UUID, name: String, nightscoutCredentials: NightscoutCredentials, lastSelectedDate: Date) {
        self.identifier = identifier
        self.name = name
        self.lastSelectedDate = lastSelectedDate
        self.nightscoutCredentials = nightscoutCredentials
    }
    
    
    //MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    
    //MARK: Equatable
    
    public static func == (lhs: Looper, rhs: Looper) -> Bool {
        //TODO: Equality should check other properties
        //See note in HUDViewModel.selectedLooper
        return lhs.identifier == rhs.identifier
    }
    

    //MARK: Identifiable
    //Conformance declaration is in LoopCaregiver app target
    //to keep SwiftUI out of LoopCaregiverKit
    
    public var id: String {
        return identifier.uuidString
    }

    
}
