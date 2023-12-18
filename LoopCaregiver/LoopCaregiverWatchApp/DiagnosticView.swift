//
//  DiagnosticView.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 12/26/23.
//

import SwiftUI

struct DiagnosticView: View {
    
    @AppStorage("lastPhoneDebugMessage", store: UserDefaults(suiteName: Bundle.main.appGroupSuiteName)) var lastPhoneDebugMessage: String = ""
    
    var body: some View {
        VStack {
            Text("This is a diagnostics view for the watch.")
            Text(lastPhoneDebugMessage)
        }.navigationTitle("Diagnostics")
            
    }
}

#Preview {
    DiagnosticView()
}
