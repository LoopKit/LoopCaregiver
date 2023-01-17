//
//  LooperView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/18/22.
//

import SwiftUI
import NightscoutUploadKit

struct LooperView: View {
    
    @ObservedObject var looperService: LooperService
    @ObservedObject var nightscoutCredentialService: NightscoutCredentialService
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var looper: Looper
    @Binding var path: NavigationPath
    @State private var isPresentingConfirm: Bool = false
    @State private var deleteAllCommandsShowing: Bool = false
    
    init(looperService: LooperService, nightscoutCredentialService: NightscoutCredentialService, remoteDataSource: RemoteDataServiceManager, looper: Looper, path: Binding<NavigationPath>) {
        self.looperService = looperService
        self.nightscoutCredentialService = nightscoutCredentialService
        self.remoteDataSource = remoteDataSource
        self.looper = looper
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
                                try await looperService.remoteDataSource.updateData()
                            }
                        }
                        Button("Autobolus Deactivate") {
                            Task {
                                try await looperService.remoteDataSource.activateAutobolus(activate: false)
                                try await looperService.remoteDataSource.updateData()
                            }
                        }
                        Button("Closed Loop Activate") {
                            Task {
                                try await looperService.remoteDataSource.activateClosedLoop(activate: true)
                                try await looperService.remoteDataSource.updateData()
                            }
                        }
                        Button("Closed Loop Deactivate") {
                            Task {
                                try await looperService.remoteDataSource.activateClosedLoop(activate: false)
                                try await looperService.remoteDataSource.updateData()
                            }
                        }
                        Button("Reload") {
                            Task {
                                try await looperService.remoteDataSource.updateData()
                            }
                        }
                        Button("Delete All Commands", role: .destructive) {
                            deleteAllCommandsShowing = true
                        }.alert("Are you sure you want to delete all commands?", isPresented: $deleteAllCommandsShowing) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    try await looperService.remoteDataSource.deleteAllCommands()
                                    try await looperService.remoteDataSource.updateData()
                                }
                            }
                            Button("Nevermind", role: .cancel) {
                                print("Nevermind pressed")
                            }
                        }
                    }
                    Section {
                        ForEach(remoteDataSource.recentCommands, id: \._id, content: { command in
                            CommandStatusView(command: command)
                        })
                    }
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
    
    func reloadCommands() async {
        
    }
}

struct CommandStatusView: View {
    let command: NSRemoteCommandPayload
    var body: some View {
        
        VStack {
            HStack {
                Text(command.action.actionName)
                Spacer()
                Text(command.action.actionDetails)
            }
            HStack {
                Text(command.createdDate.description)
                Spacer()
                switch command.status.state {
                case .Error:
                    Text([command.status.state.rawValue, command.status.message].joined(separator: "\n"))
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
            .padding(.top)
        }
    }
}
