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
    var body: some Scene {
        WindowGroup {
            ContentView(composer: ServiceComposerProduction())
        }
    }
}
