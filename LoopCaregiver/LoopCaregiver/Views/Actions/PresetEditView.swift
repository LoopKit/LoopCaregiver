//
//  PresetEditView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/7/23.
//

import NightscoutKit
import SwiftUI

struct PresetEditView: View {
    
    let preset: TemporaryScheduleOverride
    @ObservedObject var viewModel: OverrideViewModel
    
    var body: some View {
        Form {
            HStack {
                Text(preset.presentableDescription())
                    .font(.largeTitle)
                Spacer()
            }
            OverrideInsulinNeedsView(ratioComplete: preset.insulinNeedsScaleFactor ?? 1.0)
            VStack (alignment: .leading) {
                if let targetDescription = preset.targetRangePresentableDescription() {
                    Text(targetDescription)
                        .font(.caption)
                }
            }
            Toggle("Enable Indefinitely", isOn: $viewModel.enableIndefinitely)
            if !viewModel.enableIndefinitely {
                CustomDatePicker(hourSelection: $viewModel.durationHourSelection, minuteSelection: $viewModel.durationMinuteSelection)
            }
            Spacer()
        }
    }
}

struct PresetEditView_Previews: PreviewProvider {
    static var previews: some View {
        let preset = TemporaryScheduleOverride(duration: 60.0 * 60.0, targetRange: ClosedRange(uncheckedBounds: (110, 130)), insulinNeedsScaleFactor: 1.1, symbol: "🏃", name: "Running")
        return PresetEditView(preset: preset, viewModel: OverrideViewModel())
    }
}
