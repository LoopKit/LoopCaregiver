//
//  OverrideView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutKit
import Combine

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
                        if viewModel.pickerSelectedOverride != nil {
                            HStack {
                                //Loading Pickers when there is a nil selection causes consolve warnings
                                Picker("Overrides", selection: $viewModel.pickerSelectedOverride) {
                                    ForEach(overrideState.availableOverrides, id: \.self) { overrideValue in
                                        Text(overrideValue.presentableDescription()).tag(overrideValue as TemporaryScheduleOverride?)
                                            .fontWeight(overrideValue == viewModel.activeOverride ? .heavy : .regular)
                                    }
                                }.pickerStyle(.wheel)
                                    .labelsHidden()
                            }
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
            if let editingPreset = viewModel.pickerSelectedOverride {
                PresetEditView( preset: editingPreset, viewModel: viewModel)
                    .navigationBarBackButtonHidden()
                    .navigationBarItems(leading: Button(action: {
                        viewModel.experimentalEditPresetShowing = false
                        viewModel.pickerSelectedOverride = nil
                    }) {
                        Text("Back")
                    })
                    .navigationBarItems(trailing: Button(action: {
                        viewModel.experimentalEditPresetShowing = false
                        viewModel.pickerSelectedOverride = nil
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
                        ForEach(overrideState.availableOverrides) { preset in
                            experimentalPresetButtonRow(preset: preset)
                        }
                    }
                }
            }
        }
    }
    
    func experimentalPresetButtonRow(preset: TemporaryScheduleOverride) -> some View {
        Button(action: {
            viewModel.pickerSelectedOverride = preset
            viewModel.experimentalEditPresetShowing = true
        }, label: {
            PresetRowView(preset: preset) {
                viewModel.pickerSelectedOverride = preset
            }
            .background(Color.white.opacity(0.000001)) //To get taps to work
        })
        .buttonStyle(.plain)
    }
}

class OverrideViewModel: ObservableObject, Identifiable {
    
    var delegate: OverrideViewDelegate? = nil
    var deliveryCompleted: (() -> Void)? = nil
    var cancellables = [AnyCancellable]()
    
    @Published var overrideListState: OverrideListState = .loading
    @Published var pickerSelectedOverride: TemporaryScheduleOverride?
    @Published var activeOverride: TemporaryScheduleOverride?
    @Published var lastDeliveryError: Error? = nil
    @Published var deliveryInProgress: Bool = false
    @Published var enableIndefinitely: Bool = false
    @Published var durationHourSelection = 0
    @Published var durationMinuteSelection = 0
    @Published var durationExpanded = false
    @Published var experimentalEditPresetShowing = false
    
    init() {
        bindPickerSelection()
        bindEnableIndefinitely()
    }
    
    func bindPickerSelection() {
        $pickerSelectedOverride.sink { val in
            if let duration = val?.duration, duration > 0  {
                self.enableIndefinitely = false
                let (hours, minutes) = duration.hoursAndMinutes()
                self.durationHourSelection = hours
                self.durationMinuteSelection = minutes
            } else {
                self.enableIndefinitely = true
            }
            self.durationExpanded = false
        }.store(in: &cancellables)
    }
    
    func bindEnableIndefinitely() {
        $enableIndefinitely.sink { enable in
            if enable {
                self.durationHourSelection = 0
                self.durationMinuteSelection = 0
                self.durationExpanded = false
            } else {
                if let duration = self.activeOverride?.duration, duration != 0 {
                    let hours = Int(duration / 3600)
                    let minutes = (Int(duration) - (hours * 3600)) / 60
                    self.durationHourSelection = hours
                    self.durationMinuteSelection = minutes
                } else {
                    self.durationHourSelection = 1
                    self.durationMinuteSelection = 0
                }
            }
        }.store(in: &cancellables)
    }
    
    var selectedDuration: TimeInterval {
        return TimeInterval(durationHourSelection * 3600) + TimeInterval(durationMinuteSelection * 60)
    }
    
    var selectedDefaultDuration: TimeInterval? {
        guard let pickerSelectedOverride else {return nil}
        if case .loadingComplete(let overrideState) = overrideListState {
            if let availOverride = overrideState.availableOverrides.first(where: {$0.id == pickerSelectedOverride.id}) {
                return availOverride.duration
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    var indefiniteOverridesAllowed: Bool {
        guard let selectedDefaultDuration else {return false}
        if selectedDefaultDuration > 0 {
            return false //Remote APIs don't support flagging overrides as indefinite yet
        } else {
            return true
        }
    }
    
    var actionButtonEnabled: Bool {
        readyForDelivery
    }
    
    var actionButtonType: ActionButtonType {
        if let pickerSelectedOverride = pickerSelectedOverride,
           pickerSelectedOverride == activeOverride, activeOverride?.duration == selectedDuration {
            return .cancel
        } else {
            return .update
        }
    }
    
    var activeOverrideDescription: String {
        if let activeOverride = activeOverride {
            return activeOverride.presentableDescription()
        } else {
            return "-"
        }
    }
    
    var activeOverrideDuration: Double? {
        guard let duration = pickerSelectedOverride?.duration else { return nil }
        return duration
    }
    
    var selectedHoursAndMinutesDescription: String {
        
        let (hours, minutes) = (durationHourSelection, durationMinuteSelection)
        
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
    
    private var readyForDelivery: Bool {
        return !deliveryInProgress && overrideIsSelectedForUpdate
    }
    
    var updatingProgressVisible: Bool {
        return deliveryInProgress
    }
    
    private var overrideIsSelectedForUpdate: Bool {
        if case .loadingComplete(let overrideState) = overrideListState {
            return overrideState.availableOverrides.count > 0
        } else {
            return false
        }
    }
    
    @MainActor
    private func loadOverrides() async {
        
        guard let delegate else {return}
        
        overrideListState = .loading
        
        do {
            let overrideState = try await delegate.overrideState()
            guard overrideState.availableOverrides.count > 0 else {
                enum OverrideViewLoadError: LocalizedError {
                    case emptyOverrides
                    var errorDescription: String? { return "No Overrides Available"}
                }
                throw OverrideViewLoadError.emptyOverrides
            }
            overrideListState = .loadingComplete(overrideState: overrideState)
            if let activeOverride = overrideState.activeOverride {
                self.pickerSelectedOverride = activeOverride
                self.activeOverride = activeOverride
            } else if let firstOverride = overrideState.availableOverrides.first {
                self.pickerSelectedOverride = firstOverride
            }
        } catch {
            overrideListState = .loadingError(error)
        }
    }
    
    @MainActor
    func setup(delegate: OverrideViewDelegate, deliveryCompleted: (() -> Void)?) async {
        self.delegate = delegate
        self.deliveryCompleted = deliveryCompleted
        await loadOverrides()
    }

    
    //MARK: Actions
    
    @MainActor
    func cancelActiveOverrideButtonTapped() async {
        guard let delegate else {return}
        
        deliveryInProgress = true
        
        do {
            try await delegate.cancelOverride()
            deliveryCompleted?()
        } catch {
            lastDeliveryError = error
        }
        
        deliveryInProgress = false
    }
    
    @MainActor
    func updateButtonTapped() async {
        
        guard let delegate else {return}
        
        deliveryInProgress = true
        
        do {
            if let selectedOverride = pickerSelectedOverride {
                try await delegate.startOverride(overrideName: selectedOverride.name ?? "",
                                                                       durationTime: selectedDuration)
            } else {
                //TODO: Throw error
            }
            deliveryCompleted?()
        } catch {
            lastDeliveryError = error
        }
        
        deliveryInProgress = false
    }
    
    func reloadOverridesTapped() async {
        await self.loadOverrides()
    }
    
    
    //MARK: Models
    
    enum OverrideListState {
        case loading
        case loadingError(_ error: Error)
        case loadingComplete(overrideState: OverrideState)
    }
    
    enum ActionButtonType {
        case cancel
        case update
    }
}

protocol OverrideViewDelegate {
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws
    func overrideState() async throws -> OverrideState
    func cancelOverride() async throws
}

struct OverrideState: Equatable {
    let activeOverride: TemporaryScheduleOverride?
    let availableOverrides: [TemporaryScheduleOverride]
}


struct OverrideView_Previews: PreviewProvider {
    static var previews: some View {
        let overrides = OverrideViewPreviewMock.mockOverrides
        let delegate = OverrideViewPreviewMock(currentOverride: overrides.first, presets: overrides)
        return OverrideView(delegate: delegate)
    }
}

struct OverrideViewPreviewMock: OverrideViewDelegate {
    
    var currentOverride: TemporaryScheduleOverride?
    
    var presets: [NightscoutKit.TemporaryScheduleOverride]
    
    func overrideState() async throws -> OverrideState {
        //throw OverrideViewPreviewMockError.NetworkError //For testing
        return OverrideState(activeOverride: currentOverride, availableOverrides: presets)
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

extension RemoteDataServiceManager: OverrideViewDelegate {
    func overrideState() async throws -> OverrideState {
        return OverrideState(activeOverride: activeOverride(), availableOverrides: currentProfile?.settings.overridePresets ?? [])
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
