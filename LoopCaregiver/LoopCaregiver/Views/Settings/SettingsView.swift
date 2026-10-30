//
//  SettingsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import Combine
import LoopCaregiverKit
import LoopKitUI
import SwiftUI
import WidgetKit

// swiftlint:disable file_length
// swiftlint:disable type_body_length
struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var looperService: LooperService
    @ObservedObject var nightscoutCredentialService: NightscoutCredentialService
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var watchService: WatchService
    @ObservedObject private var analytics = CaregiverAnalytics.shared
    @Binding var showSheetView: Bool
    @State private var isPresentingConfirm = false
    @State private var path = NavigationPath()
    @State private var deleteAllCommandsShowing = false
    @State private var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    @State private var maxCarbAmountPickerShowing = false
    private let maxCarbAmountIncrements = Array(stride(from: 0, through: 100, by: 5))
    @State private var maxBolusAmountPickerShowing = false
    private let maxBolusIncrements = Array(stride(from: 0, through: 10, by: 1))

    init(
        looperService: LooperService,
        accountService: AccountServiceManager,
        settings: CaregiverSettings,
        watchService: WatchService,
        showSheetView: Binding<Bool>
    ) {
        self.settingsViewModel = SettingsViewModel(
            selectedLooper: looperService.looper,
            accountService: accountService,
            settings: settings
        )
        self.looperService = looperService
        self.nightscoutCredentialService = NightscoutCredentialService(
            credentials: looperService.looper.nightscoutCredentials
        )
        self.accountService = accountService
        self.settings = settings
        self.watchService = watchService
        self._showSheetView = showSheetView
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                looperSection
                addNewLooperSection
                commandsSection
                deliveryLimitsSection
                unitsSection
                timelineSection
                if let profileExpiration = BuildDetails.default.profileExpiration {
                    appExpirationSection(profileExpiration: profileExpiration)
                }
                watchSection
                privacySection
                experimentalSection
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.showSheetView = false
                    }, label: {
                        Text("Done").bold()
                    })
                }
            }
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
            .navigationDestination(
                for: String.self
            ) { _ in
                LooperSetupView(accountService: accountService, settings: settings, path: $path)
            }
        }
        .onAppear {
            self.glucosePreference = settings.glucosePreference
        }
        .onChange(of: glucosePreference, perform: { _ in
            if settings.glucosePreference != glucosePreference {
                settings.glucosePreference = glucosePreference
            }
        })
        .confirmationDialog("Are you sure?",
                            isPresented: $isPresentingConfirm) {
            Button("Remove \(looperService.looper.name)?", role: .destructive) {
                do {
                    try accountService.removeLooper(looperService.looper)
                    if !path.isEmpty {
                        path.removeLast()
                    }
                } catch {
                    // TODO: Show errors here
                    print("Error removing loop user")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    var addNewLooperSection: some View {
        Section {
            NavigationLink(value: "AddLooper") {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                        .accessibilityLabel(Text("Add New Looper"))
                    Text("Add New Looper")
                }
            }
        }
    }

    var looperSection: some View {
        Section {
            Picker("Looper", selection: $settingsViewModel.selectedLooper) {
                ForEach(settingsViewModel.loopers()) { looper in
                    Text(looper.name).tag(looper)
                }
            }
            .pickerStyle(.automatic)
            LabeledContent {
                Text(loopURL)
            } label: {
                Text("Nightscout")
            }
            LabeledContent {
                Text(nightscoutCredentialService.otpCode)
            } label: {
                Text("OTP")
            }
            Button(role: .destructive) {
                isPresentingConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("Remove")
                    Spacer()
                }
            }
        }
    }

    var loopURL: String {
        if settings.demoModeEnabled {
            return "https://www.YourLoopersURL.com"
        } else {
            return nightscoutCredentialService.credentials.url.absoluteString
        }
    }

    var deliveryLimitsSection: some View {
        Section {
            LabeledContent("Max Carbs", value: String(settings.maxCarbAmount) + " g")
                .background(Color.white.opacity(0.0000001)) // support tap
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    withAnimation(.linear) {
                        maxCarbAmountPickerShowing.toggle()
                    }
                }
            if maxCarbAmountPickerShowing {
                Picker(selection: $settings.maxCarbAmount, label: Text("")) {
                    ForEach(maxCarbAmountIncrements, id: \.self) { value in
                        Text("\(value)")
                            .tag(value)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .pickerStyle(.wheel)
            }
            LabeledContent("Max Bolus", value: String(settings.maxBolusAmount) + " U")
                .background(Color.white.opacity(0.0000001)) // support tap
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    withAnimation(.linear) {
                        maxBolusAmountPickerShowing.toggle()
                    }
                }
            if maxBolusAmountPickerShowing {
                Picker(selection: $settings.maxBolusAmount, label: Text("")) {
                    ForEach(maxBolusIncrements, id: \.self) { value in
                        Text("\(value)")
                            .tag(value)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .pickerStyle(.wheel)
            }
            Text("Delivery limits only apply to this app. These do not change Loop or Nightscout settings.")
                .font(.footnote)
        } header: {
            SectionHeader(label: "Delivery Limits")
        }
    }

    var unitsSection: some View {
        Section {
            Picker("Glucose", selection: $glucosePreference, content: {
                ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                    Text(item.presentableDescription).tag(item)
                })
            })
        } header: {
            SectionHeader(label: "Units")
        }
    }

    var timelineSection: some View {
        Section {
            Toggle("Show Prediction", isOn: $settings.timelinePredictionEnabled)
        }  header: {
            SectionHeader(label: "Timeline")
        }
    }
    
    @ViewBuilder var watchSection: some View {
        Section {
            Button("Setup Watch") {
                do {
                    try activateLoopersOnWatch()
                } catch {
                    print("Error activating Loopers on watch: \(error)")
                }
            }

            Text("Setup will transfer all Loopers to Caregiver on your Apple Watch.")
                .font(.footnote)
            LabeledContent("Watch App Open", value: watchService.isReachable() ? "YES" : "NO")
        } header: {
            SectionHeader(label: "Apple Watch")
        }
    }

    var privacySection: some View {
        Section {
            NavigationLink {
                UsageDataPrivacyPreferenceView(analytics: analytics, onboardingMode: false)
            } label: {
                LabeledContent("Usage Data Sharing", value: analytics.usageDataPrivacyPreference.title)
            }
        } header: {
            SectionHeader(label: "Privacy")
        }
    }

    @ViewBuilder var experimentalSection: some View {
        if settings.experimentalFeaturesUnlocked || settings.remoteCommands2Enabled {
            Section {
                Toggle("Remote Commands 2", isOn: $settings.remoteCommands2Enabled)
                Text("Remote commands 2 requires a special Nightscout deploy and Loop version. This will enable command status and other features. See Zulip #caregiver for details")
                    .font(.footnote)
            } header: {
                SectionHeader(label: "Remote Commands")
            }
            Section {
                LabeledContent("User ID", value: accountService.selectedLooper?.id ?? "")
                Button(action: {
                    WidgetCenter.shared.invalidateConfigurationRecommendations()
                }, label: {
                    Text("Invalidate Recommendations")
                })
                Button(action: {
                    WidgetCenter.shared.reloadAllTimelines()
                }, label: {
                    Text("Reload Timeline")
                })
                Toggle("Demo Mode", isOn: $settings.demoModeEnabled)
                Text("Demo mode hides sensitive data for Caregiver presentations.")
                    .font(.footnote)
                Button("Copy Deep Link") {
                    UIPasteboard.general.string = addLooperDeepLink
                }
                Text("WARNING: A deep link should NEVER be shared as it holds your Looper's secrets which will allow remote bolusing/carbs. Tapping the above row will copy the deep link to your clipboard. You can paste the link to the Safari URL field on another phone. It will open Caregiver, if installed, and add your Looper like you went through the setup process. This is useful if you have a phone without a camera for scanning the QR code.")
                    .font(.footnote)
            } header: {
                SectionHeader(label: "Diagnostics")
            }
        } else {
            Section {
                Text("Disabled                             ")
                    .simultaneousGesture(LongPressGesture(minimumDuration: 5.0).onEnded { _ in
                        settings.experimentalFeaturesUnlocked = true
                    })
            } header: {
                SectionHeader(label: "Diagnostics")
            }
        }
    }

    func activateLoopersOnWatch() throws {
        do {
            try watchService.sendLoopersToWatch()
        } catch {
            print("Error activating Loopers \(error)")
        }
    }

    var addLooperDeepLink: String {
        guard let selectedLooper = accountService.selectedLooper else {
            return ""
        }
        do {
            let deepLink = try CreateLooperDeepLink.deepLinkWithLooper(selectedLooper)
            return deepLink.url.absoluteString
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }

    var commandsSection: some View {
        Group {
            if !looperService.remoteDataSource.recentCommands.isEmpty {
                Section {
                    ForEach(looperService.remoteDataSource.recentCommands, id: \.id, content: { command in
                        CommandStatusView(command: command)
                    })
                }  header: {
                    SectionHeader(label: "Recent Remote Commands")
                }
            }
            if settings.remoteCommands2Enabled {
                Section("Remote Special Actions") {
                    Button("Autobolus Activate") {
                        Task {
                            do {
                                try await looperService.remoteDataSource.activateAutobolus(activate: true)
                                await looperService.remoteDataSource.updateData()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    Button("Autobolus Deactivate") {
                        Task {
                            do {
                                try await looperService.remoteDataSource.activateAutobolus(activate: false)
                                await looperService.remoteDataSource.updateData()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    Button("Closed Loop Activate") {
                        Task {
                            do {
                                try await looperService.remoteDataSource.activateClosedLoop(activate: true)
                                await looperService.remoteDataSource.updateData()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    Button("Closed Loop Deactivate") {
                        Task {
                            do {
                                try await looperService.remoteDataSource.activateClosedLoop(activate: false)
                                await looperService.remoteDataSource.updateData()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    Button("Reload") {
                        Task {
                            await looperService.remoteDataSource.updateData()
                        }
                    }
                    Button("Delete All Commands", role: .destructive) {
                        deleteAllCommandsShowing = true
                    }.alert("Are you sure you want to delete all commands?", isPresented: $deleteAllCommandsShowing) {
                        Button("Delete", role: .destructive) {
                            Task {
                                do {
                                    try await looperService.remoteDataSource.deleteAllCommands()
                                    await looperService.remoteDataSource.updateData()
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        Button("Nevermind", role: .cancel) {
                            print("Nevermind pressed")
                        }
                    }
                }
            }
        }
    }

    /*
     DIY loop specific component to show users the amount of time remaining on their build before a rebuild is necessary.
     */
    private func appExpirationSection(profileExpiration: Date) -> some View {
        let expirationDate = AppExpirationAlerter.calculateExpirationDate(profileExpiration: profileExpiration)
        let isTestFlight = AppExpirationAlerter.isTestFlightBuild()
        let nearExpiration = AppExpirationAlerter.isNearExpiration(expirationDate: expirationDate)
        let profileExpirationMsg = AppExpirationAlerter.createProfileExpirationSettingsMessage(expirationDate: expirationDate)
        let readableExpirationTime = Self.dateFormatter.string(from: expirationDate)

        if isTestFlight {
            return createAppExpirationSection(
                headerLabel: NSLocalizedString(
                    "TestFlight",
                    bundle: .main,
                    comment: "Settings app TestFlight section"
                ),
                footerLabel: NSLocalizedString(
                    "TestFlight expires ",
                    bundle: .main,
                    comment: "Time that build expires"
                ) + readableExpirationTime,
                expirationLabel: NSLocalizedString(
                    "TestFlight Expiration",
                    bundle: .main,
                    comment: "Settings TestFlight expiration view"
                ),
                updateURL: "https://loopkit.github.io/loopdocs/gh-actions/gh-update/",
                nearExpiration: nearExpiration,
                expirationMessage: profileExpirationMsg
            )
        } else {
            return createAppExpirationSection(
                headerLabel: NSLocalizedString(
                    "App Profile",
                    bundle: .main,
                    comment: "Settings app profile section"
                ),
                footerLabel: NSLocalizedString(
                    "Profile expires ",
                    bundle: .main,
                    comment: "Time that profile expires"
                ) + readableExpirationTime,
                expirationLabel: NSLocalizedString(
                    "Profile Expiration",
                    bundle: .main,
                    comment: "Settings App Profile expiration view"
                ),
                updateURL: "https://loopkit.github.io/loopdocs/build/updating/",
                nearExpiration: nearExpiration,
                expirationMessage: profileExpirationMsg
            )
        }
    }

    // swiftlint:disable function_parameter_count
    private func createAppExpirationSection(
        // swiftlint:enable function_parameter_count
        headerLabel: String,
        footerLabel: String,
        expirationLabel: String,
        updateURL: String,
        nearExpiration: Bool,
        expirationMessage: String
    ) -> some View {
        return Section(
            header: SectionHeader(label: headerLabel),
            footer: Text(footerLabel)
        ) {
            if nearExpiration {
                Text(expirationMessage).foregroundColor(.red)
            } else {
                HStack {
                    Text(expirationLabel)
                    Spacer()
                    Text(expirationMessage).foregroundColor(Color.secondary)
                }
            }
            Button(action: {
                UIApplication.shared.open(URL(string: updateURL)!)
            }, label: {
                Text(
                    NSLocalizedString(
                        "How to update (LoopDocs)",
                        bundle: .main,
                        comment: "The title text for how to update"
                    )
                )
            })
        }
    }

    private static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter // formats date like "February 4, 2023 at 2:35 PM"
    }()
}
// swiftlint:enable type_body_length

#Preview {
    let composer = ServiceComposerPreviews()
    let looper = composer.accountServiceManager.selectedLooper!
    var showSheetView = true
    let showSheetBinding = Binding<Bool>(get: { showSheetView }, set: { showSheetView = $0 })
    let looperService = composer.accountServiceManager.createLooperService(
        looper: looper
    )
    return SettingsView(
        looperService: looperService,
        accountService: composer.accountServiceManager,
        settings: composer.settings,
        watchService: composer.watchService,
        showSheetView: showSheetBinding
    )
}

class SettingsViewModel: ObservableObject {
    @Published var selectedLooper: Looper {
        didSet {
            do {
                try accountService.updateActiveLoopUser(selectedLooper)
            } catch {
                print(error)
            }
        }
    }
    @ObservedObject var accountService: AccountServiceManager
    private var settings: CaregiverSettings
    private var subscribers: Set<AnyCancellable> = []

    init(selectedLooper: Looper, accountService: AccountServiceManager, settings: CaregiverSettings) {
        self.selectedLooper = selectedLooper
        self.accountService = accountService
        self.settings = settings

        self.accountService.$selectedLooper.sink { _ in
        } receiveValue: { [weak self] updatedUser in
            if let self, let updatedUser, self.selectedLooper != updatedUser {
                self.selectedLooper = updatedUser
            }
        }.store(in: &subscribers)
    }

    func loopers() -> [Looper] {
        return accountService.loopers
    }
}

struct CommandStatusView: View {
    let command: RemoteCommand
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(command.action.actionName)
                Spacer()
                Text(command.createdDate, style: .time)
            }
            Text(command.action.actionDetails)
            switch command.status.state {
            case .error:
                Text([command.status.message].joined(separator: "\n"))
                    .foregroundColor(Color.red)
            case .inProgress:
                Text(command.status.state.title)
                    .foregroundColor(Color.blue)
            case .success:
                Text(command.status.state.title)
                    .foregroundColor(Color.green)
            case .pending:
                Text(command.status.state.title)
                    .foregroundColor(Color.blue)
            }
        }
    }
}
// swiftlint:enable file_length
