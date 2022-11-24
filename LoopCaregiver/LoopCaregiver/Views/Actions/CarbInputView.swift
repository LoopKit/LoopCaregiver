//
//  CarbInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct CarbInputView: View {

    var looperService: LooperService
    @Binding var showSheetView: Bool
    @State var carbInput: String = ""
    @State var duration: String = "3"
    @State private var buttonDisabled = false
    @State private var isPresentingConfirm: Bool = false
    @FocusState private var carbInputViewIsFocused: Bool
    
    var unitFrameWidth: CGFloat {
        return 20.0
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    LabeledContent {
                        TextField(
                            "0",
                            text: $carbInput
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .focused($carbInputViewIsFocused)
                        .onAppear(perform: {
                            carbInputViewIsFocused = true
                        })
                        Text("g")
                            .frame(width: unitFrameWidth)
                    } label: {
                        Text("Amount Consumed")
                    }
                    LabeledContent {
                        TextField(
                            "",
                            text: $duration
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        Text("hr")
                            .frame(width: unitFrameWidth)
                    } label: {
                        Text("Absorption Time")
                    }
                }
                Button("Deliver") {
                    isPresentingConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(buttonDisabled)
                .padding()
                .confirmationDialog("Are you sure?",
                                    isPresented: $isPresentingConfirm) {
                    Button("Deliver \(carbInput)g of carbs to \(looperService.looper.name)?", role: .none) {
                        buttonDisabled = true
                        Task {
                            if let carbAmountInGrams = Int(carbInput), let durationInHours = Float(duration) {
                                let _ = try await looperService.remoteDataSource.deliverCarbs(amountInGrams: carbAmountInGrams, durationInHours: durationInHours)
                                buttonDisabled = true
                                showSheetView = false
                            }
                        }
                        //TODO: Remove this when errors are presented to the user
                        showSheetView = false
                    }
                    Button("Cancel", role: .cancel) {
                        buttonDisabled = false
                    }
                }
            }
            .navigationBarTitle(Text("Add Carb Entry"), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                self.showSheetView = false
            }) {
                Text("Cancel")
            })
        }
        
    }
}

