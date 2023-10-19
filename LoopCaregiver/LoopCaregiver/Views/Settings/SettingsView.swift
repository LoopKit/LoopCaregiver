//
//  SettingsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import Combine

struct SettingsView: View {

    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var looperService: LooperService
    @ObservedObject var nightscoutCredentialService: NightscoutCredentialService
    @ObservedObject var accountService: AccountServiceManager
    @ObservedObject var settings: CaregiverSettings
    @Binding var showSheetView: Bool
    @State private var isPresentingConfirm: Bool = false
    @State private var path = NavigationPath()
    @State private var deleteAllCommandsShowing: Bool = false
    @State private var glucosePreference: GlucoseUnitPrefererence = .milligramsPerDeciliter
    
    init(looperService: LooperService, accountService: AccountServiceManager, settings: CaregiverSettings, showSheetView: Binding<Bool>) {
        self.settingsViewModel = SettingsViewModel(selectedLooper: looperService.looper, accountService: looperService.accountService, settings: settings)
        self.looperService = looperService
        self.nightscoutCredentialService = NightscoutCredentialService(credentials: looperService.looper.nightscoutCredentials)
        self.accountService = accountService
        self.settings = settings
        self._showSheetView = showSheetView
    }
    
    var body: some View {
        NavigationStack (path: $path) {
            Form {
                looperSection
                addNewLooperSection
                commandsSection
                unitsSection
                timelineSection
                experimentalSection
            }
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.showSheetView = false
            }) {
                Text("Done").bold()
            })
            .navigationDestination(
                for: String.self
            ) { val in
                LooperSetupView(accountService: accountService, settings: settings, path: $path)
            }
        }
        .onAppear {
            self.glucosePreference = settings.glucoseUnitPreference
        }
        .onChange(of: glucosePreference, perform: { value in
            if settings.glucoseUnitPreference != glucosePreference {
                settings.saveGlucoseUnitPreference(glucosePreference)
            }
        })
        .confirmationDialog("Are you sure?",
                            isPresented: $isPresentingConfirm) {
            Button("Remove \(looperService.looper.name)?", role: .destructive) {
                do {
                    try looperService.accountService.removeLooper(looperService.looper)
                    if !path.isEmpty {
                        path.removeLast()
                    }
                } catch {
                    //TODO: Show errors here
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
                Text(settings.demoModeEnabled ? "https://www.YourLoopersURL.com" : nightscoutCredentialService.credentials.url.absoluteString)
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
    
    var unitsSection: some View {
        Section("Units") {
            Picker("Glucose", selection: $glucosePreference, content: {
                ForEach(GlucoseUnitPrefererence.allCases, id: \.self, content: { item in
                    Text(item.presentableDescription).tag(item)
                })
            })
        }
    }
    
    var timelineSection: some View {
        Section("Timeline") {
            Toggle("Show Prediction", isOn: $settings.timelinePredictionEnabled)
        }
    }
    
    var experimentalSection: some View {
        Section("Experimental Features") {
            if settings.experimentalFeaturesUnlocked || settings.remoteCommands2Enabled {
                Toggle("Remote Commands 2", isOn: $settings.remoteCommands2Enabled)
                Text("Remote commands 2 requires a special Nightscout deploy and Loop version. This will enable command status and other features. See Zulip #caregiver for details")
                    .font(.footnote)
                LabeledContent("App Groups", value: settings.appGroupsSupported ? "Enabled" : "Disabled")
                Text("App Groups are required for Widgets to function.")
                    .font(.footnote)
                Toggle("Demo Mode", isOn: $settings.demoModeEnabled)
                Text("Demo mode hides sensitive data for Caregiver presentations.")
                    .font(.footnote)
                if !settings.demoModeEnabled {
                    Text(addLooperDeepLink)
                        .textSelection(.enabled)
                }
            } else {
                Text("Disabled                             ")
                    .simultaneousGesture(LongPressGesture(minimumDuration: 5.0).onEnded { _ in
                        settings.experimentalFeaturesUnlocked = true
                    })
            }
        }
    }
    
    var addLooperDeepLink: String {
        guard let selectedLooper = accountService.selectedLooper else {
            return ""
        }
        guard let otpURL = URL(string: selectedLooper.nightscoutCredentials.otpURL) else {
            return ""
        }
        let secretKey = selectedLooper.nightscoutCredentials.secretKey
        let deepLink = CreateLooperDeepLink(name: selectedLooper.name, nsURL: selectedLooper.nightscoutCredentials.url, secretKey: secretKey, otpURL: otpURL)
        do {
            return try deepLink.toURL()
        } catch {
            return ""
        }

    }
    
    var commandsSection: some View {
        Group {
            Section(remoteCommandSectionText) {
                ForEach(looperService.remoteDataSource.recentCommands, id: \.id, content: { command in
                    CommandStatusView(command: command)
                })
            }
            if looperService.settings.remoteCommands2Enabled {
                Section("Remote Special Actions") {
                    Button("Autobolus Activate") {
                        Task {
                            try await looperService.remoteDataSource.activateAutobolus(activate: true)
                            await looperService.remoteDataSource.updateData()
                        }
                    }
                    Button("Autobolus Deactivate") {
                        Task {
                            try await looperService.remoteDataSource.activateAutobolus(activate: false)
                            await looperService.remoteDataSource.updateData()
                        }
                    }
                    Button("Closed Loop Activate") {
                        Task {
                            try await looperService.remoteDataSource.activateClosedLoop(activate: true)
                            await looperService.remoteDataSource.updateData()
                        }
                    }
                    Button("Closed Loop Deactivate") {
                        Task {
                            try await looperService.remoteDataSource.activateClosedLoop(activate: false)
                            await looperService.remoteDataSource.updateData()
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
                                try await looperService.remoteDataSource.deleteAllCommands()
                                await looperService.remoteDataSource.updateData()
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
    
    func looperRowView(looper: Looper) -> some View {
        HStack {
            Button {
                accountService.selectedLooper = looper
            } label: {
                if looper == accountService.selectedLooper {
                    Image(systemName: "circle.fill")
                        .opacity(0.75)
                } else {
                    Image(systemName: "circle")
                        .opacity(0.75)
                }
            }
            .buttonStyle(PlainButtonStyle())
            NavigationLink(value: looper) {
                Text(looper.name)
            }
        }
    }
    
    var remoteCommandSectionText: String {
        if looperService.settings.remoteCommands2Enabled {
            return "Remote Commands"
        } else {
            return "Remote Command Errors"
        }
    }
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
        
        self.accountService.$selectedLooper.sink { val in
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
            case .Error:
                Text([command.status.message].joined(separator: "\n"))
                    .foregroundColor(Color.red)
            case .InProgress:
                Text(command.status.state.title)
                    .foregroundColor(Color.blue)
            case .Success:
                Text(command.status.state.title)
                    .foregroundColor(Color.green)
            case .Pending:
                Text(command.status.state.title)
                    .foregroundColor(Color.blue)
            }
        }
    }
}
