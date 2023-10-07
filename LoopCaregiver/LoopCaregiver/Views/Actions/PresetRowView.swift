//
//  PresetRowView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/7/23.
//

import NightscoutKit
import SwiftUI

struct PresetRowView: View {
    
    let preset: TemporaryScheduleOverride
    var scheduleTapBlock: (() -> Void)
    
    var body: some View {
        HStack {
            Text(preset.symbol ?? "")
                .font(.largeTitle)
            VStack (alignment: .leading) {
                Text(preset.name ?? "")
                if let targetDescription = preset.targetRangePresentableDescription() {
                    Text(targetDescription)
                        .font(.caption)
                }
                OverrideInsulinNeedsView(ratioComplete: preset.insulinNeedsScaleFactor ?? 1.0)
                    .frame(width: 125.0, height: 8.0)
            }
            Spacer()
            VStack {
                Spacer()
                durationView
                Spacer()
            }
        }
    }
    
    var durationView: some View {
        HStack (spacing: 2) {
            Image(systemName: "timer")
                .labelStyle(.titleAndIcon)
            Text(preset.presentedHourAndMinutes)
        }.font(.caption)
    }
}
