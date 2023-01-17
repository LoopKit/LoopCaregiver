//
//  LocalizationUtils.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/5/22.
//

import Foundation

struct LocalizationUtils {
    
    static func presentableStringFromBolusAmount(_ amount: Double) -> String {
        return localizedNumberString(input: amount, maxFractionalDigits: 2)
    }
    
    static func doubleFromUserInput(_ string: String) -> Double? {
        let numFormatter = NumberFormatter()
        return numFormatter.number(from: string) as? Double
    }
    
    static func localizedNumberString(input: Double, maxFractionalDigits: Int? = nil) -> String {
        let numberFormatter = NumberFormatter()
        if let maxFractionalDigits {
            numberFormatter.maximumFractionDigits = maxFractionalDigits
        }
        numberFormatter.roundingMode = .halfUp
        return numberFormatter.string(from: input as NSNumber) ?? "\(input)"
    }
    
    static func presentableMinutesFormat(timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        var result = "\(minutes) minute"
        if minutes == 0 || minutes > 1 {
            result += "s"
        }
        
        return result
    }
}
