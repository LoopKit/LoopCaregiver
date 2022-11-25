//
//  BolusInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct BolusInputView: View {

    let looperService: LooperService
    @Binding var showSheetView: Bool
    @State var bolusAmount: String = ""
    @State var duration: String = ""
    @State private var buttonDisabled = false
    @State private var isPresentingConfirm: Bool = false
    @FocusState private var bolusInputViewIsFocused: Bool
    
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
                            text: $bolusAmount
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .focused($bolusInputViewIsFocused)
                        .onAppear(perform: {
                            bolusInputViewIsFocused = true
                        })
                        Text("U")
                            .frame(width: unitFrameWidth)
                    } label: {
                        Text("Bolus")
                    }
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
                    Button("Deliver \(bolusAmount) of insulin to \(looperService.looper.name)?", role: .none) {
                        buttonDisabled = true
                        Task {
                            if let bolusAmountInUnits = Double(bolusAmount) {
                                let _ = try await looperService.remoteDataSource.deliverBolus(amountInUnits: bolusAmountInUnits)
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
