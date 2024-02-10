//
//  LoopCaregiverApp.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import LoopCaregiverKit
import SwiftUI

@main
struct LoopCaregiverApp: App {
    let composer = ServiceComposerProduction()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(composer.accountServiceManager)
                .environmentObject(composer.settings)
                .environmentObject(composer.watchSession)
        }
    }
}
