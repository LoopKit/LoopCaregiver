//
//  CarbInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct CarbInputView: View {

    @ObservedObject var looper: Looper
    @Binding var showSheetView: Bool
    @State var carbInput: String = ""
    @State var duration: String = "3"
    @State private var buttonDisabled = false
    @State private var isPresentingConfirm: Bool = false
    @FocusState private var carbInputViewIsFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    HStack {
                        Text("Amount Consumed")
                        Spacer()
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
                    }
                    HStack {
                        Text("Absorption Time")
                        TextField(
                            "",
                            text: $duration
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        Text("hr")
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
                    Button("Deliver \(carbInput)g of carbs?", role: .none) {
                        buttonDisabled = true
                        Task {
                            if let carbAmountInGrams = Int(carbInput), let durationInHours = Float(duration) {
                                let _ = try await looper.nightscoutDataSource.deliverCarbs(amountInGrams: carbAmountInGrams, durationInHours: durationInHours)
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

