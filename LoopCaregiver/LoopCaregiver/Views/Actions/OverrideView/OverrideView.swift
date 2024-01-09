//
//  OverrideView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import LoopCaregiverKit
import NightscoutKit
import SwiftUI

struct OverrideView: View {
    
    var delegate: OverrideViewDelegate
    @StateObject private var viewModel = OverrideViewModel()
    var deliveryCompleted: (() -> Void)? = nil
    
    private var experimentalMode = false
    
    init(delegate: OverrideViewDelegate, deliveryCompleted: (() -> Void)? = nil){
        self.delegate = delegate
        self.deliveryCompleted = deliveryCompleted
    }
    
    @ViewBuilder
    var body: some View {
        if experimentalMode {
            experimentalBodyView
        } else {
            VStack {
                pickerContainerView
                deliveryStatusContainerView
                actionButton
            }
            .onAppear(perform: {
                Task {
                    await viewModel.setup(delegate: delegate, deliveryCompleted: deliveryCompleted)
                }
            })
        }
    }
    
    @ViewBuilder
    var pickerContainerView: some View {
        HStack {
            switch viewModel.overrideListState {
            case .loading:
                ProgressView("Loading Overrides...")
            case .loadingError(let error):
                reloadButtonView(error: error)
            case .loadingComplete(let overrideState):
                Form {
                    Section (){
                        HStack {
                            //Loading Pickers when there is a nil selection causes console warnings
                            Picker("Overrides", selection: $viewModel.pickerSelectedRow) {
                                Text("None").tag(nil as OverridePickerRowModel?)
                                ForEach(overrideState.pickerRows(), id: \.self) { row in
                                    Text(row.presentableDescription()).tag(row as OverridePickerRowModel?)
                                        .fontWeight(row.isActive ? .heavy : .regular)
                                }
                            }.pickerStyle(.wheel)
                                .labelsHidden()
                        }
                        if viewModel.pickerSelectedRow != nil {
                            durationContainerView
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var durationContainerView: some View {
        Group {
            Toggle("Enable Indefinitely", isOn: $viewModel.enableIndefinitely)
                .disabled(!viewModel.indefiniteOverridesAllowed)
            if !viewModel.enableIndefinitely {
                LabeledContent("Duration", value: viewModel.selectedHoursAndMinutesDescription)
                    .background(Color.white.opacity(0.0000001)) //support tap
                    .onTapGesture {
                        withAnimation(.linear) {
                            viewModel.durationExpanded.toggle()
                        }
                    }
                if viewModel.durationExpanded {
                    if !viewModel.enableIndefinitely {
                        CustomDatePicker(hourSelection: $viewModel.durationHourSelection, minuteSelection: $viewModel.durationMinuteSelection)
                    }
                }
            }
            if !viewModel.indefiniteOverridesAllowed {
                Text("Overrides with default durations can't be set to indefinite.")
                    .font(.footnote)
            }
        }
    }
    
    @ViewBuilder
    var deliveryStatusContainerView: some View {
        Group {
            if let error = viewModel.lastDeliveryError {
                Text(error.localizedDescription)
                    .foregroundColor(.critical)
            }
            if viewModel.updatingProgressVisible {
                ProgressView("Requesting...")
            }
        }
    }
    
    @ViewBuilder
    func reloadButtonView(error: Error) -> some View {
        VStack {
            Button(action: {
                Task {
                    await viewModel.reloadOverridesTapped()
                }
            }, label: {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25.0, height: 25.0)
            })
            Text(error.localizedDescription)
        }
    }
    
    @ViewBuilder
    var actionButton: some View {
        Group {
            switch viewModel.actionButtonType {
            case .cancel:
                    Button("End Override", role: .destructive) {
                        Task {
                            await viewModel.cancelActiveOverrideButtonTapped()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.actionButtonEnabled)
                    .frame(maxWidth: .infinity)
            case .update:
                    Button("Start Override") {
                        Task {
                            await viewModel.updateButtonTapped()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.actionButtonEnabled)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    //MARK: Experimental Presets View
    
    @ViewBuilder
    var experimentalBodyView: some View {
        VStack {
            experimentalPresetsView
            deliveryStatusContainerView
            Spacer()
        }
        .navigationDestination(isPresented: $viewModel.experimentalEditPresetShowing, destination: {
            if let editingPreset = viewModel.experimentalSelectedOverride {
                PresetEditView( preset: editingPreset, viewModel: viewModel)
                    .navigationBarBackButtonHidden()
                    .navigationBarItems(leading: Button(action: {
                        viewModel.experimentalEditPresetShowing = false
                        viewModel.experimentalSelectedOverride = nil
                    }) {
                        Text("Back")
                    })
                    .navigationBarItems(trailing: Button(action: {
                        viewModel.experimentalEditPresetShowing = false
                        viewModel.experimentalSelectedOverride = nil
                    }) {
                        Text("Enable")
                    })
            }
        })
        .onAppear(perform: {
            Task {
                await viewModel.setup(delegate: delegate, deliveryCompleted: deliveryCompleted)
            }
        })
    }
    @ViewBuilder
    var experimentalPresetsView: some View {
        Form {
            switch viewModel.overrideListState {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView("Loading Overrides...")
                    Spacer()
                }
            case .loadingError(let error):
                HStack {
                    Spacer()
                    reloadButtonView(error: error)
                    Spacer()
                }
            case .loadingComplete(let overrideState):
                if let activeOverride = viewModel.activeOverride {
                    Section("Active") {
                        experimentalPresetButtonRow(preset: activeOverride)
                    }
                }
                
                Section ("Presets") {
                    VStack(spacing: 10) {
                        ForEach(overrideState.presets) { preset in
                            experimentalPresetButtonRow(preset: preset)
                        }
                    }
                }
            }
        }
    }
    
    func experimentalPresetButtonRow(preset: TemporaryScheduleOverride) -> some View {
        Button(action: {
            viewModel.experimentalSelectedOverride = preset
            viewModel.experimentalEditPresetShowing = true
        }, label: {
            PresetRowView(preset: preset) {
                viewModel.experimentalSelectedOverride = preset
            }
            .background(Color.white.opacity(0.000001)) //To get taps to work
        })
        .buttonStyle(.plain)
    }
}

struct OverrideState: Equatable {
    let activeOverride: TemporaryScheduleOverride?
    let presets: [TemporaryScheduleOverride]
    
    func pickerRows() -> [OverridePickerRowModel] {
        return presets.map { preset in
            if let activeOverride = activeOverride, activeOverride.name == preset.name {
                return OverridePickerRowModel(preset: preset, activeOverride: activeOverride)
            } else {
                return OverridePickerRowModel(preset: preset, activeOverride: nil)
            }
        }
    }
}

struct OverrideView_Previews: PreviewProvider {
    static var previews: some View {
        let overrides = OverrideViewPreviewMock.mockOverrides
        let delegate = OverrideViewPreviewMock(currentOverride: overrides.first, presets: overrides)
        return OverrideView(delegate: delegate)
    }
}

protocol OverrideViewDelegate {
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws
    func overrideState() async throws -> OverrideState
    func cancelOverride() async throws
}

extension RemoteDataServiceManager: OverrideViewDelegate {
    func overrideState() async throws -> OverrideState {
        return OverrideState(activeOverride: activeOverride(), presets: currentProfile?.settings.overridePresets ?? [])
    }
}

struct OverrideViewPreviewMock: OverrideViewDelegate {
    
    var currentOverride: TemporaryScheduleOverride?
    
    var presets: [NightscoutKit.TemporaryScheduleOverride]
    
    func overrideState() async throws -> OverrideState {
        //throw OverrideViewPreviewMockError.NetworkError //For testing
        return OverrideState(activeOverride: currentOverride, presets: presets)
    }
    
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        //throw OverrideViewPreviewMockError.NetworkError //Testing
        //guard let preset = presets.first(where: {$0.name == overrideName}) else {return}
        try! await Task.sleep(nanoseconds: 1 * 1_000_000_000)
    }
    
    func cancelOverride() async throws {
        
    }
    
    static var mockOverrides: [NightscoutKit.TemporaryScheduleOverride] {
        return [
            TemporaryScheduleOverride(duration: 60.0 * 60.0, targetRange: ClosedRange(uncheckedBounds: (110, 130)), insulinNeedsScaleFactor: 0.3, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0 * 90.0, targetRange: ClosedRange(uncheckedBounds: (110, 130)), insulinNeedsScaleFactor: 1.3, symbol: "🏊", name: "Swimming")
        ]
    }
    
    enum OverrideViewPreviewMockError: LocalizedError {
        case NetworkError
        
        var errorDescription: String? {
            switch self {
            case .NetworkError:
                return "Connect to the network"
            }
        }
    }
    
}

extension TemporaryScheduleOverride: Identifiable {
    public var id: String {
        return name ?? ""
    }
    
    var presentedHourAndMinutes: String {
        guard durationInMinutes() > 0 else {
            return "∞"
        }
        
        let (hours, minutes) = duration.hoursAndMinutes()
        
        var hoursPart: String? = nil
        if hours > 0 {
            hoursPart = "\(hours)h"
        }
        
        var minutesPart: String? = nil
        if minutes > 0 {
            minutesPart = "\(minutes)m"
        }

        return [hoursPart, minutesPart].compactMap({$0}).joined(separator: " ")
    }
}

