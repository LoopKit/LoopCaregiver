//
//  ColorType.swift
//
//
//  Created by Bill Gestrich on 1/22/24.
//

import HealthKit
import NightscoutKit
import SwiftUI

public enum ColorType: Int, CaseIterable, Comparable {
    
    case gray
    case green
    case yellow
    case red
    case clear
    
    public init(quantity: HKQuantity) {
        let glucose = quantity.doubleValue(for:.milligramsPerDeciliter)
        switch glucose {
        case -Double.infinity..<55:
            self = ColorType.red
        case 55..<70:
            self = ColorType.yellow
        case 70..<180:
            self = ColorType.green
        case 180..<250:
            self = ColorType.yellow
        case 250...:
            self = ColorType.red
        default:
            assertionFailure("Unexpected quantity: \(quantity)")
            self = ColorType.gray
        }
    }
    
    public var color: Color {
        switch self {
        case .gray:
            return Color.gray
        case .green:
            return Color.green
        case .yellow:
            return Color.yellow
        case .red:
            return Color.red
        case .clear:
            return Color.clear
        }
    }
    
    public static func membersAsRange() -> ClosedRange<ColorType> {
        return ColorType.allCases.first!...ColorType.allCases.last!
    }
    
    //Comparable
    public static func < (lhs: ColorType, rhs: ColorType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
