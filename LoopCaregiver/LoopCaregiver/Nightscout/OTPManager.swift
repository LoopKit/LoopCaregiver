//
//  OTPManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/14/22.
//

import SwiftUI
import OneTimePassword

class OTPManager: ObservableObject {
    
    weak var delegate: OTPManagerDelegate?
    let otpURL: String
    @Published var otpCode: String = "" {
        didSet {
            self.delegate?.otpDidUpdate(manager: self, otpCode: otpCode)
        }
    }
    
    private var timer: Timer? = nil

    init(optURL: String) {
        self.otpURL = optURL
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.refreshCurrentOTP()
        }
        refreshCurrentOTP()
    }
    
    private func getOTPCode() throws -> String? {
        let token = Token(url: URL(string: otpURL)!)
        return token?.currentPassword
    }

    private func refreshCurrentOTP() {
        do {
            self.otpCode = try getOTPCode() ?? ""
        } catch {
            print(error)
        }
    }

}

protocol OTPManagerDelegate: AnyObject {
    func otpDidUpdate(manager: OTPManager, otpCode: String)
}
