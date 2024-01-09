//
//  CustomDatePicker.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/9/24.
//

import SwiftUI

struct CustomDatePicker: View {
    @Binding var hourSelection: Int
    @Binding var minuteSelection: Int
    
    static private let maxHours = 24
    static private let maxMinutes = 60
    private let hours = [Int](0...Self.maxHours)
    private let minutes = [0, 15, 30, 45]
    
    var body: some View {
            HStack(spacing: .zero) {
                Picker(selection: $hourSelection, label: Text("")) {
                    ForEach(hours, id: \.self) { value in
                        Text("\(value) hour")
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                
                Picker(selection: $minuteSelection, label: Text("")) {
                    ForEach(minutes, id: \.self) { value in
                        Text("\(value) min")
                            .tag(value)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .pickerStyle(.wheel)
            }
    }
}
