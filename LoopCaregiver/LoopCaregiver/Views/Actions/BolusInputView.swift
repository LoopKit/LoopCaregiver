//
//  BolusInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import LoopKitUI
import LocalAuthentication

struct BolusInputView: View {

    let looperService: LooperService
    @Binding var showSheetView: Bool
    
    @State private var bolusAmount: String = ""
    @State private var duration: String = ""
    @State private var submissionInProgress = false
    @State private var isPresentingConfirm: Bool = false
    @State private var errorText: String? = nil
    @FocusState private var bolusInputViewIsFocused: Bool
    
    private let maxBolusAmount = 10.0 //TODO: Check Looper's max bolus amount
    private let unitFrameWidth: CGFloat = 20.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    bolusEntryForm
                    if let errorText {
                        Text(errorText)
                            .foregroundColor(.critical)
                    }
                    Button("Deliver") {
                        deliverButtonTapped()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(disableForm())
                    .padding()
                    .confirmationDialog("Are you sure?",
                                        isPresented: $isPresentingConfirm) {
                        Button("Deliver \(bolusAmount) of insulin to \(looperService.looper.name)?", role: .none) {
                            deliverConfirmationButtonTapped()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                .disabled(submissionInProgress)
                if submissionInProgress {
                    ProgressView()
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
    
    var bolusEntryForm: some View {
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
    }
    
    @MainActor
    private func deliverButtonTapped(){
        
        bolusInputViewIsFocused = false
        do {
            errorText = nil
            try validateForm()
            isPresentingConfirm = true
        } catch {
            errorText = error.localizedDescription
        }
        
    }
    
    @MainActor
    private func deliverConfirmationButtonTapped() {

        Task {

            let message = String(format: NSLocalizedString("Authenticate to Bolus", comment: "The message displayed during a device authentication prompt for bolus specification"))
            
            guard (await authenticationHandler(message)) else {
                errorText = "Authentication required"
                return
            }
            
            submissionInProgress = true
            do {
                try await deliverBolus()
                showSheetView = false
            } catch {
                errorText = error.localizedDescription
            }
            
            submissionInProgress = false
        }
    }
    
    private func deliverBolus() async throws {
        let fieldValues = try getBolusFieldValues()
        let _ = try await looperService.remoteDataSource.deliverBolus(amountInUnits: fieldValues.bolusAmount)
    }
    
    private func validateForm() throws {
        let _ = try getBolusFieldValues()
    }
    
    private func getBolusFieldValues() throws -> BolusInputViewFormValues {
        
        guard let bolusAmountInUnits = LocalizationUtils.doubleFromUserInput(bolusAmount),
                bolusAmountInUnits > 0,
                bolusAmountInUnits <= maxBolusAmount else {
            throw BolusInputViewError.invalidBolusAmount(maxBolusAmount: maxBolusAmount)
        }
    
        return BolusInputViewFormValues(bolusAmount: bolusAmountInUnits)
    }
    
    private func disableForm() -> Bool {
        return submissionInProgress || bolusAmount.isEmpty
    }
    
    var authenticationHandler: (String) async -> Bool = { message in
        return await withCheckedContinuation { continuation in
            LocalAuthentication.deviceOwnerCheck(message) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
}

struct BolusInputViewFormValues {
    let bolusAmount: Double
}


enum BolusInputViewError: LocalizedError {
    case invalidBolusAmount(maxBolusAmount: Double)
    
    var errorDescription: String? {
        switch self {
        case .invalidBolusAmount(let maxBolusAmount):
            let localizedAmount = LocalizationUtils.localizedNumberString(input: maxBolusAmount)
            return "Enter a valid bolus amount up to \(localizedAmount) units"
        }
    }
    
    func pluralizeHour(count: Int) -> String {
        if count > 1 {
            return "hours"
        } else {
            return "hour"
        }
    }
}

