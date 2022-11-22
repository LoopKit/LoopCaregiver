//
//  LooperSetupView.swift
//  
//
//  Created by Bill Gestrich on 5/11/22.
//

import Foundation
import SwiftUI
import CodeScanner

struct LooperSetupView: View {
    
    @ObservedObject var looperService: LooperService
    @State private var nightscoutURLFieldText: String = ""
    @State private var nameFieldText: String = ""
    @State private var apiSecretFieldText: String = ""
    @State private var qrURLFieldText: String = ""
    @State private var errorText: String?
    @State private var showingSignoutAlert = false
    @State private var isShowingScanner = false
    @Binding var path: NavigationPath
    
    var body: some View {
        
        VStack {
            Form {
                Section {
                    TextField(
                        "Name",
                        text: $nameFieldText, onCommit:
                            {
                                self.save()
                            })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    TextField(
                        "Nightscout URL",
                        text: $nightscoutURLFieldText, onCommit:
                            {
                                self.save()
                            })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    TextField(
                        "API Secret",
                        text: $apiSecretFieldText
                    ) {
                        self.save()
                    }
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    if qrURLFieldText == "" {
                        Button {
                            isShowingScanner = true
                        } label: {
                            Text("Scan QR")
                        }
                    } else {
                        TextField(
                            "QR Scan",
                            text: $qrURLFieldText, onCommit:
                                {
                                    self.save()
                                }
                        )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                }
            }
            
            Spacer()
            Button("Add Looper") {
                self.save()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding()
            .disabled(disableForm())
            if let errorText = errorText {
                Text("\(errorText)").foregroundColor(.red)
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            CodeScannerView(codeTypes: [.qr], simulatedData: simulatedOTP(), completion: handleScan)
        }
        .navigationTitle("Add Looper")
        .onAppear(perform: {
            if let simCredentials = looperService.simulatorCredentials() {
                nightscoutURLFieldText = simCredentials.url.absoluteString
                nameFieldText = "Jill-\(Int.random(in: 0...100))"
                apiSecretFieldText = simCredentials.secretKey
                qrURLFieldText = simCredentials.otpURL
            }
        })
        
    }
    
    private func disableForm() -> Bool {
        return !nameFieldValid() || !nightscoutURLFieldValid() || !apiSecretFieldValid() || !qrURLFieldValid()
    }
    
    //TODO: This should just check if empty... And have separate methods if valid that can throw errors.
    
    private func nightscoutURLFieldValid() -> Bool {
        return !nightscoutURLFieldText.isEmpty
    }
    
    private func nameFieldValid() -> Bool {
        return !nameFieldText.isEmpty
    }
    
    private func apiSecretFieldValid() -> Bool {
        return !apiSecretFieldText.isEmpty
    }
    
    private func qrURLFieldValid() -> Bool {
        return !qrURLFieldText.isEmpty
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            qrURLFieldText = result.string
        case .failure(let error):
            //TODO: Show error message
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    private func save(){
        do {
            errorText = ""
            //TODO: Validate URL and show error
            try save(nightscoutURL: nightscoutURLFieldText, name: nameFieldText, apiSecret: apiSecretFieldText, otpURL: qrURLFieldText)
            path.removeLast()
        } catch {
            errorText = "\(error.localizedDescription)"
        }
    }
    
    func save(nightscoutURL: String?, name: String?, apiSecret: String?, otpURL: String?) throws {
        
        guard let name = name, name.count > 0 else {
            throw AccountViewModelError.genericError(message: "Must enter Looper Name")
        }
        
        guard let nightscoutURL = nightscoutURL, nightscoutURL.count > 0 else {
            throw AccountViewModelError.genericError(message: "Must enter Nightscout URL")
        }
        
        guard let apiSecret = apiSecret, apiSecret.count > 0 else {
            throw AccountViewModelError.genericError(message: "Must enter API Secret")
        }
        
        guard let otpURL = otpURL, otpURL.count > 0 else {
            throw AccountViewModelError.genericError(message: "Must enter OTPURL")
        }

        //TODO: Remove force cast
        let looper = Looper(name: name, nightscoutCredentials: NightscoutCredentials(url: URL(string: nightscoutURL)!, secretKey: apiSecret, otpURL: otpURL), lastSelectedDate: Date())
        
        try looperService.addLooper(looper)
        try looperService.updateActiveLoopUser(looper)
    }
    
    func simulatedOTP() -> String {
        if let url = looperService.simulatorCredentials()?.otpURL {
            return url
        } else {
            return ""
        }
    }
}

enum AccountViewModelError: LocalizedError {
    case genericError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .genericError(let message):
            return message
        }
    }
}
