//
//  CaregiverAnalytics.swift
//  LoopCaregiver
//
//  Created by Pete Schwamb on 10/25/26.
//

import Amplitude
import Foundation

// Same cases and raw values as Loop's UsageDataPrivacyPreference.
enum UsageDataPrivacyPreference: String, CaseIterable {
    case noSharing
    case shareInstallationStatsOnly
    case shareUsageDetailsWithDevelopers
}

// Reports to LoopKit's analytics (ingest.loopkit.org) the way Loop does: the
// app version at launch for "Share Version Only", and usage events too for
// "Share Usage Data". Never glucose values or amounts.
final class CaregiverAnalytics: ObservableObject {
    static let shared = CaregiverAnalytics()

    static let defaultPreference = UsageDataPrivacyPreference.shareInstallationStatsOnly

    // Caregiver's own key, so its devices are counted apart from Loop's.
    // No client is created while this is empty.
    private static let apiKey = ""
    private static let serverURL = "https://ingest.loopkit.org/v1/events"
    private static let preferenceKey = "com.loopkit.LoopCaregiver.UsageDataPrivacyPreference"

    private let userDefaults: UserDefaults
    private var client: Amplitude?

    // Version only until the caregiver chooses otherwise, including for
    // anyone who installed Caregiver before there was a choice.
    @Published private(set) var usageDataPrivacyPreference: UsageDataPrivacyPreference

    // The choice is asked for once, before the first Looper is added.
    var hasChosenPreference: Bool {
        Self.storedPreference(in: userDefaults) != nil
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.usageDataPrivacyPreference = Self.storedPreference(in: userDefaults) ?? Self.defaultPreference
        createClient()
    }

    func updateUsageDataPrivacyPreference(_ newValue: UsageDataPrivacyPreference) {
        userDefaults.set(newValue.rawValue, forKey: Self.preferenceKey)
        guard newValue != usageDataPrivacyPreference else {
            return
        }
        usageDataPrivacyPreference = newValue
        if newValue == .noSharing {
            client = nil
        } else if client == nil {
            createClient()
        }
    }

    private static func storedPreference(in userDefaults: UserDefaults) -> UsageDataPrivacyPreference? {
        userDefaults.string(forKey: preferenceKey).flatMap(UsageDataPrivacyPreference.init(rawValue:))
    }

    private func createClient() {
#if targetEnvironment(simulator)
        return
#else
        guard usageDataPrivacyPreference != .noSharing, !Self.apiKey.isEmpty else {
            return
        }
        let amplitude = Amplitude()
        amplitude.setTrackingOptions(AMPTrackingOptions().disableCity().disableCarrier().disableIDFA().disableLatLng().disableIPAddress().disableRegion())
        amplitude.initializeApiKey(Self.apiKey)
        amplitude.setServerUrl(Self.serverURL)
        client = amplitude
        client?.logEvent("LoopCaregiverAnalytics instantiation", withEventProperties: buildProperties)
#endif
    }

    private var buildProperties: [String: Any] {
        var properties: [String: Any] = [:]
        properties["buildNumber"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        properties["workspaceBranch"] = BuildDetails.default.workspaceGitBranch
        properties["workspaceRevision"] = BuildDetails.default.workspaceGitRevision
        return properties
    }

    // MARK: Usage events

    func recordAppLaunch() {
        recordEvent("App Launch")
    }

    func recordBolusScreen() {
        recordEvent("Bolus Screen")
    }

    func recordCarbEntryScreen() {
        recordEvent("Carb Entry Screen")
    }

    func recordOverrideScreen() {
        recordEvent("Override Screen")
    }

    func recordSettingsScreen() {
        recordEvent("Settings Screen")
    }

    func recordBolusSent() {
        recordEvent("Bolus set")
    }

    func recordCarbEntrySent() {
        recordEvent("Carb entry created")
    }

    func recordOverrideEnacted() {
        recordEvent("Override Enacted")
    }

    func recordOverrideEnded() {
        recordEvent("Override Ended")
    }

    private func recordEvent(_ name: String) {
        guard usageDataPrivacyPreference == .shareUsageDetailsWithDevelopers else {
            return
        }
        client?.logEvent(name)
    }
}
