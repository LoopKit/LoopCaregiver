//
//  TimeInterval.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/7/23.
//

import Foundation

extension TimeInterval {
    func hoursAndMinutes() -> (hours: Int, minute: Int) {
        let hours = Int(self / 3600)
        let minutes = (Int(self) - (hours * 3600)) / 60
        return (hours, minutes)
    }
}
