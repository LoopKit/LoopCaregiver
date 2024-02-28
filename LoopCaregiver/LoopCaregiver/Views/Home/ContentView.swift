//
//  ContentView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import LoopCaregiverKit
import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var accountService: AccountServiceManager
    var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject var settings: CaregiverSettings
    @EnvironmentObject var watchService: WatchService
    
    @State var deepLinkErrorShowing = false
    @State var deepLinkErrorText: String = ""
    
    var body: some View {
        return Group {
            if let looper = accountService.selectedLooper {
                HomeView(looperService: accountService.createLooperService(looper: looper, settings: settings), watchService: watchService)
            } else {
                FirstRunView(accountService: accountService, settings: settings, showSheetView: true)
            }
        }.onOpenURL(perform: { (url) in
            Task {
                do {
                    try await deepLinkHandler.handleDeepLinkURL(url)
                } catch {
                    deepLinkErrorShowing = true
                    deepLinkErrorText = error.localizedDescription
                }
            }
        })
        .alert(deepLinkErrorText, isPresented: $deepLinkErrorShowing) {
            Button(role: .cancel) {
            } label: {
                Text("OK")
            }
        }
        .background(AppExpirationAlerterRepresentable())
    }
}
