//
//  LocalizationUtils.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/5/22.
//

import Foundation

struct LocalizationUtils {
    
    static func doubleFromUserInput(_ string: String) -> Double? {
        let numFormatter = NumberFormatter()
        return numFormatter.number(from: string) as? Double
    }
    
    static func localizedNumberString(input: Double, maxFractionalDigits: Int? = nil) -> String {
        let numberFormatter = NumberFormatter()
        if let maxFractionalDigits {
            numberFormatter.maximumFractionDigits = maxFractionalDigits
        }
        numberFormatter.roundingMode = .down
        return numberFormatter.string(from: input as NSNumber) ?? "\(input)"
    }
}
