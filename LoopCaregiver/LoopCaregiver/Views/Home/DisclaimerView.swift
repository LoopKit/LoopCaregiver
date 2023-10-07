//
//  DisclaimerView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 2/12/23.
//

import SwiftUI

struct DisclaimerView: View {
    
    @ObservedObject var viewModel = DisclaimerViewModel()
    
    var disclaimerAgreedTo: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                List (viewModel.lines, id: \.value) { line in
                    Text(line.value)
                        .font(.callout)
                }
                .scrollIndicators(.visible)
                Button("Continue With Risks") {
                    disclaimerAgreedTo()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
            }.navigationTitle("Warning!")
        }
    }
}

struct CustomButton: View {
    @State var toggleOn: Bool = false
    var body: some View {
        Button {
            toggleOn = !toggleOn
        } label: {
            if toggleOn {
                Image(systemName: "circle.circle.fill")
            } else {
                Image(systemName: "circle")
            }
        }
    }
}

struct DisclaimerLine: Identifiable, Equatable {
    let id = UUID()
    let value: String
}

class DisclaimerViewModel: ObservableObject {
    @Published var lines: [DisclaimerLine]
    
    init(){
        self.lines = [
            DisclaimerLine(value: "Loop Remote code, such as this Caregiver app, are highly experimental and may be subject to issues that could cause serious risks to one's health/life."),
            DisclaimerLine(value: "The developers make no claims regarding its safety and do not recommend anyone use experimental code. You take full responsibility for running this code and do so at your own risk."),
            DisclaimerLine(value: "The Loop community's forums should be closely monitored for app updates, if available."),
            DisclaimerLine(value: "Bugs could cause information in the app to be incorrect or out-of-date."),
            DisclaimerLine(value: "This app and Nightscout may not reflect all delivered treatments (i.e. Due to network delays or bugs). You must be aware of this to avoid delivering dangerous, duplicate treatments to Loop."),
            DisclaimerLine(value: "The Nightscout QR code and API Key should be secured. Anyone with this information can remotely send treatments (bolus, carbs, etc)."),
            DisclaimerLine(value: "The phone with Caregiver installed should have a locking mechanism. Anyone with access to the Caregiver app can remotely send treatments (bolus, carbs, etc). If a phone is lost or stolen, the QR code in Loop's Settings should be reset."),
            DisclaimerLine(value: "There may be other risks not known or mentioned here."),
        ]
    }
}
