//
//  LoopCaregiverWatchApp.swift
//  LoopCaregiverWatchApp Watch App
//
//  Created by Bill Gestrich on 10/27/23.
//

import LoopCaregiverKit
import SwiftUI

@main
struct LoopCaregiverWatchApp: App {
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
