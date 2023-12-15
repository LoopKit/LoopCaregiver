//
//  LocalizationUtils.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/5/22.
//

import Foundation
import HealthKit

public struct LocalizationUtils {
    
    public static func presentableStringFromBolusAmount(_ amount: Double) -> String {
        return localizedNumberString(input: amount, maxFractionalDigits: 2)
    }
    
    public static func presentableStringFromGlucoseAmount(_ amount: Double, displayUnits: HKUnit) -> String {
        var minFractionalDigits = 0
        var maxFractionalDigits = 0
        if displayUnits == .millimolesPerLiter {
            minFractionalDigits = 1
            maxFractionalDigits = 1
        }
        return LocalizationUtils.localizedNumberString(input: amount, minFractionalDigits: minFractionalDigits, maxFractionalDigits: maxFractionalDigits)
    }
    
    public static func presentableStringFromHoursAmount(_ amount: Double) -> String {
        return localizedNumberString(input: amount, maxFractionalDigits: 2)
    }
    
    public static func doubleFromUserInput(_ unverifiedInput: String) -> Double? {
        guard let normalizedInput = normalizeDecimalInput(unverifiedInput) else {
            return nil
        }
        let numFormatter = NumberFormatter()
        return numFormatter.number(from: normalizedInput) as? Double
    }
    
    private static func localizedNumberString(input: Double, minFractionalDigits: Int? = nil, maxFractionalDigits: Int? = nil) -> String {
        let numberFormatter = NumberFormatter()
        if let minFractionalDigits {
            numberFormatter.minimumFractionDigits = minFractionalDigits
        }
        if let maxFractionalDigits {
            numberFormatter.maximumFractionDigits = maxFractionalDigits
        }
        numberFormatter.roundingMode = .halfUp
        return numberFormatter.string(from: input as NSNumber) ?? "\(input)"
    }
    
    public static func presentableMinutesFormat(timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        var result = "\(minutes) minute"
        if minutes == 0 || minutes > 1 {
            result += "s"
        }
        
        return result
    }
    
    private static func normalizeDecimalInput(_ input: String) -> String? {
        
        var result = input
        
        result = result.trimmingCharacters(in: .whitespaces)
  
        //Considered this but it seems risky to adjust decimal parts.
        //Need to also consider entries like 1,000.2 which inlude a
        //command decimal
//        if result.contains(".") && Locale.current.decimalSeparator == "," {
//            result = result.replacingOccurrences(of: ".", with: ",")
//        }
//
//        if result.contains(",") && Locale.current.decimalSeparator == "." {
//            result = result.replacingOccurrences(of: ",", with: ".")
//        }
        
        let containsDecimalSeparator = result.contains(",") || result.contains(".")
        if !containsDecimalSeparator && result.starts(with: "0") {
            //Don't allow inputs like "01"
            //as they likely meant 0.1
            return nil
        }
        
        return result
    }
}
