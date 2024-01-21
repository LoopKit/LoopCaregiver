//
//  OTPManager.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/14/22.
//

import OneTimePassword
import SwiftUI

public class OTPManager: ObservableObject {
    
    public weak var delegate: OTPManagerDelegate?
    public let otpURL: String
    @Published public var otpCode: String = "" {
        didSet {
            self.delegate?.otpDidUpdate(manager: self, otpCode: otpCode)
        }
    }
    
    private var timer: Timer? = nil

    public init(optURL: String) {
        self.otpURL = optURL
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.refreshCurrentOTP()
        }
        refreshCurrentOTP()
    }
    
    private func getOTPCode() throws -> String? {
        let token = try Token(url: URL(string: otpURL)!)
        return token.currentPassword
    }

    private func refreshCurrentOTP() {
        do {
            self.otpCode = try getOTPCode() ?? ""
        } catch {
            print(error)
        }
    }

}

public protocol OTPManagerDelegate: AnyObject {
    func otpDidUpdate(manager: OTPManager, otpCode: String)
}
