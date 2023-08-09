//
//  LooperView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/18/22.
//

import SwiftUI
import NightscoutKit

struct LooperView: View {
    
    @ObservedObject var looper: Looper
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var looperService: LooperService
    @ObservedObject var nightscoutCredentialService: NightscoutCredentialService
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @Binding var path: NavigationPath
    @State private var isPresentingConfirm: Bool = false
    @State private var deleteAllCommandsShowing: Bool = false
    
    init(looper: Looper, accountServiceManager: AccountServiceManager, settings: CaregiverSettings, path: Binding<NavigationPath>) {
        self.looper = looper
        self.settings = settings
        let looperService = accountServiceManager.createLooperService(looper: looper, settings: settings)
        self.looperService = looperService
        self.nightscoutCredentialService = NightscoutCredentialService(credentials: looperService.looper.nightscoutCredentials)
        self.remoteDataSource = looperService.remoteDataSource

        self._path = Binding(projectedValue: path)
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    LabeledContent {
                        Text(nightscoutCredentialService.credentials.url.absoluteString)
                    } label: {
                        Text("Nightscout")
                    }
                    LabeledContent {
                        Text(nightscoutCredentialService.otpCode)
                    } label: {
                        Text("OTP")
                    }
                }
                Section {
                    HStack {
                        Spacer()
                        Button("Remove", role: .destructive) {
                            isPresentingConfirm = true
                        }
                        Spacer()
                    }
                }
                if looperService.settings.remoteCommands2Enabled {
                    Section {
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
                Section(remoteCommandSectionText) {
                    ForEach(remoteDataSource.recentCommands, id: \.id, content: { command in
                        CommandStatusView(command: command)
                    })
                }
            }
        }
        .confirmationDialog("Are you sure?",
                            isPresented: $isPresentingConfirm) {
            Button("Remove \(looper.name)?", role: .destructive) {
                do {
                    try looperService.accountService.removeLooper(looper)
                    path.removeLast()
                } catch {
                    //TODO: Show errors here
                    print("Error removing loop user")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationBarTitle(Text(looper.name), displayMode: .inline)
    }
    
    var remoteCommandSectionText: String {
        if looperService.settings.remoteCommands2Enabled {
            return "Remote Commands"
        } else {
            return "Remote Command Errors"
        }
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
                Text(command.status.state.rawValue)
                    .foregroundColor(Color.blue)
            case .Success:
                Text(command.status.state.rawValue)
                    .foregroundColor(Color.green)
            case .Pending:
                Text(command.status.state.rawValue)
                    .foregroundColor(Color.blue)
            }
        }
    }
}
