//
//  LoopCaregiverApp.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import SwiftUI

@main
struct LoopCaregiverApp: App {
    
    //TODO: Remove singleton
    let persistenceController = CoreDataAccountService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
