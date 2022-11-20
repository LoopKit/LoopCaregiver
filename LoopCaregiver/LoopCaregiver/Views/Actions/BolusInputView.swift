//
//  BolusInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct BolusInputView: View {

    @ObservedObject var looper: Looper
    @Binding var showSheetView: Bool
    @State var bolusAmount: String = ""
    @State var duration: String = ""
    @State private var buttonDisabled = false
    @State private var isPresentingConfirm: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    TextField(
                        "Bolus units",
                        text: $bolusAmount
                    )
                    .keyboardType(.decimalPad)
                }
                Button("Deliver") {
                    isPresentingConfirm = true
                }
                .disabled(buttonDisabled)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .confirmationDialog("Are you sure?",
                                    isPresented: $isPresentingConfirm) {
                    Button("Deliver \(bolusAmount) of insulin?", role: .none) {
                        buttonDisabled = true
                        Task {
                            if let bolusAmountInUnits = Double(bolusAmount), let otpCode = Int(looper.otpCode) {
                                let _ = try await looper.nightscoutService.deliverBolus(amountInUnits: bolusAmountInUnits, otp: otpCode)
                                buttonDisabled = false
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
            .navigationBarTitle(Text("Bolus"), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                self.showSheetView = false
            }) {
                Text("Cancel")
            })
        }
    }
}

