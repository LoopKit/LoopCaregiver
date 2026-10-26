//
//  FirstRunView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/20/24.
//

import Foundation
import LoopCaregiverKit
import SwiftUI

struct FirstRunView: View {
    @ObservedObject var accountService: AccountServiceManager
    let settings: CaregiverSettings
    @ObservedObject private var analytics = CaregiverAnalytics.shared
    @State private var showSheetView = true
    @State private var path = NavigationPath()
    @State private var sharingPreferenceChosen = CaregiverAnalytics.shared.hasChosenPreference

    var body: some View {
        NavigationStack(path: $path) {
            if sharingPreferenceChosen {
                LooperSetupView(accountService: accountService, settings: settings, path: $path)
            } else {
                UsageDataPrivacyPreferenceView(analytics: analytics, onboardingMode: true) {
                    sharingPreferenceChosen = true
                }
            }
        }
    }
}
