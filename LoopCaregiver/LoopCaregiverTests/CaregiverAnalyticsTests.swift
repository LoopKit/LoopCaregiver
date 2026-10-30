//
//  CaregiverAnalyticsTests.swift
//  LoopCaregiverTests
//
//  Created by Pete Schwamb on 10/25/26.
//

@testable import LoopCaregiver
import XCTest

final class CaregiverAnalyticsTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private let suiteName = "CaregiverAnalyticsTests"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testPreference_WhenNeverChosen_IsVersionOnly() {
        // Arrange
        let analytics = CaregiverAnalytics(userDefaults: userDefaults)

        // Assert
        XCTAssertEqual(analytics.usageDataPrivacyPreference, .shareInstallationStatsOnly)
        XCTAssertFalse(analytics.hasChosenPreference)
    }

    func testPreference_WhenChosen_PersistsAcrossLaunches() {
        // Arrange
        let analytics = CaregiverAnalytics(userDefaults: userDefaults)

        // Act
        analytics.updateUsageDataPrivacyPreference(.noSharing)
        let relaunched = CaregiverAnalytics(userDefaults: userDefaults)

        // Assert
        XCTAssertEqual(relaunched.usageDataPrivacyPreference, .noSharing)
        XCTAssertTrue(relaunched.hasChosenPreference)
    }

    func testPreference_WhenDefaultConfirmed_CountsAsChosen() {
        // Arrange
        let analytics = CaregiverAnalytics(userDefaults: userDefaults)

        // Act
        analytics.updateUsageDataPrivacyPreference(.shareInstallationStatsOnly)

        // Assert
        XCTAssertTrue(analytics.hasChosenPreference)
        XCTAssertEqual(analytics.usageDataPrivacyPreference, .shareInstallationStatsOnly)
    }

    func testPreference_WhenStoredValueUnknown_IsVersionOnly() {
        // Arrange
        userDefaults.set("somethingElse", forKey: "com.loopkit.LoopCaregiver.UsageDataPrivacyPreference")

        // Act
        let analytics = CaregiverAnalytics(userDefaults: userDefaults)

        // Assert
        XCTAssertEqual(analytics.usageDataPrivacyPreference, .shareInstallationStatsOnly)
        XCTAssertFalse(analytics.hasChosenPreference)
    }
}
