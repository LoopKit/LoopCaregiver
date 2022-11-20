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
//    
//    init(nightscoutService: NightscoutService, looper: Looper, showSheetView: Binding<Bool>) {
//        self.nightscoutService = nightscoutService
//        self.looper = looper
//        self.showSheetView = showSheetView
//    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    TextField(
                        "Carbs (grams)",
                        text: $carbInput
                    )
                    .keyboardType(.decimalPad)
                    TextField(
                        "Duration",
                        text: $duration
                    )
                    .keyboardType(.decimalPad)
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
                            if let carbAmountInGrams = Int(carbInput), let durationInHours = Float(duration), let otpCode = Int(looper.otpCode) {
                                let _ = try await looper.nightscoutService.deliverCarbs(amountInGrams: carbAmountInGrams, amountInHours: durationInHours, otp: otpCode)
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

