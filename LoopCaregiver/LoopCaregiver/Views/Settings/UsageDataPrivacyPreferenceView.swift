//
//  UsageDataPrivacyPreferenceView.swift
//  LoopCaregiver
//
//  Created by Pete Schwamb on 10/25/26.
//

import LoopKitUI
import SwiftUI

// Loop's Share Data screen, worded for Caregiver. In onboarding it has a
// Continue button; from Settings each choice applies as it is tapped.
struct UsageDataPrivacyPreferenceView: View {
    @ObservedObject var analytics: CaregiverAnalytics
    var onboardingMode: Bool
    var didFinish: (() -> Void)?

    @State private var preference: UsageDataPrivacyPreference

    init(analytics: CaregiverAnalytics, onboardingMode: Bool, didFinish: (() -> Void)? = nil) {
        self.analytics = analytics
        self.onboardingMode = onboardingMode
        self.didFinish = didFinish
        self._preference = State(initialValue: analytics.usageDataPrivacyPreference)
    }

    var body: some View {
        ConfigurationPageScrollView(content: {
            Text("You can optionally choose to share usage data with Loop developers to improve Caregiver. Sharing is not required, and Caregiver will function fully no matter which option you choose. Usage data will not be shared with third parties.")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
                .padding()
            Card {
                chooser
            }
        }, actionArea: {
            if onboardingMode {
                Spacer()
                Button(action: {
                    analytics.updateUsageDataPrivacyPreference(preference)
                    didFinish?()
                }, label: {
                    Text("Continue")
                        .actionButtonStyle(.primary)
                })
                .padding()
            }
        })
        .navigationTitle(Text("Share Data"))
        .navigationBarHidden(false)
        .onChange(of: preference) { newValue in
            if !onboardingMode {
                analytics.updateUsageDataPrivacyPreference(newValue)
            }
        }
    }

    private var chooser: some View {
        VStack(alignment: .leading) {
            choice(
                title: "No Sharing",
                description: "Do not share any data.",
                sharingPreference: .noSharing
            )
            choice(
                title: "Share Version Only",
                description: "Anonymously share minimal data about this Caregiver version, to help developers know how many people are using Caregiver. Which device, and operating system version will also be shared.",
                sharingPreference: .shareInstallationStatsOnly
            )
            choice(
                title: "Share Usage Data",
                description: "In addition to version information, anonymously share data about how Caregiver is being used on your phone. Usage data includes events like opening Caregiver, sending boluses, carbs and overrides, and navigating between screens. It does not include health data like glucose values or dosing amounts.",
                sharingPreference: .shareUsageDetailsWithDevelopers
            )
        }
    }

    private func choice(title: String, description: String, sharingPreference: UsageDataPrivacyPreference) -> CheckmarkListItem {
        CheckmarkListItem(
            title: Text(title),
            description: Text(description),
            isSelected: Binding(
                get: { preference == sharingPreference },
                set: { isSelected in
                    if isSelected {
                        preference = sharingPreference
                    }
                }
            )
        )
    }
}

extension UsageDataPrivacyPreference {
    var title: String {
        switch self {
        case .noSharing:
            return "No Sharing"
        case .shareInstallationStatsOnly:
            return "Share Version Only"
        case .shareUsageDetailsWithDevelopers:
            return "Share Usage Data"
        }
    }
}
