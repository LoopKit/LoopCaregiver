//
//  OverrideViewModel.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/9/24.
//

import Combine
import Foundation
import NightscoutKit

class OverrideViewModel: ObservableObject, Identifiable {
    
    var delegate: OverrideViewDelegate? = nil
    var deliveryCompleted: (() -> Void)? = nil
    var cancellables = [AnyCancellable]()
    
    @Published var overrideListState: OverrideListState = .loading
    @Published var pickerSelectedRow: OverridePickerRowModel?
    @Published var experimentalSelectedOverride: TemporaryScheduleOverride?
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
        $pickerSelectedRow.sink { val in
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
    
    var pickerSelectedDuration: TimeInterval {
        return TimeInterval(durationHourSelection * 3600) + TimeInterval(durationMinuteSelection * 60)
    }
    
    var indefiniteOverridesAllowed: Bool {
        guard let pickerSelectedRow else {return false}
        return pickerSelectedRow.indefiniteDurationAllowed
    }
    
    var actionButtonEnabled: Bool {
        readyForDelivery
    }
    
    var actionButtonType: ActionButtonType {
        if let pickerSelectedRow = pickerSelectedRow{
            if pickerSelectedRow.isActive, activeOverride?.duration == pickerSelectedDuration {
                return .cancel
            } else {
                return .update
            }
        } else {
            return .cancel
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
        guard let duration = pickerSelectedRow?.duration else { return nil }
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
            return overrideState.presets.count > 0
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
            guard overrideState.presets.count > 0 else {
                enum OverrideViewLoadError: LocalizedError {
                    case emptyOverrides
                    var errorDescription: String? { return "No Overrides Available"}
                }
                throw OverrideViewLoadError.emptyOverrides
            }
            overrideListState = .loadingComplete(overrideState: overrideState)
            if let activeOverride = overrideState.activeOverride, let preset = overrideState.presets.first(where: {$0.name == activeOverride.name}) {
                self.pickerSelectedRow = OverridePickerRowModel(preset: preset, activeOverride: activeOverride)
                self.activeOverride = activeOverride
            } else {
                self.pickerSelectedRow = nil
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
            if let selectedOverride = pickerSelectedRow {
                try await delegate.startOverride(overrideName: selectedOverride.name ?? "",
                                                                       durationTime: pickerSelectedDuration)
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
    
    enum OverrideListState: Equatable {
        
        case loading
        case loadingError(_ error: Error)
        case loadingComplete(overrideState: OverrideState)
        
        static func == (lhs: OverrideViewModel.OverrideListState, rhs: OverrideViewModel.OverrideListState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.loadingError(let lhsError), .loadingError(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            case (.loadingComplete(let lhsState), .loadingComplete(let rhsState)):
                return lhsState == rhsState
            default:
                return false
            }
        }
    }
    
    enum ActionButtonType {
        case cancel
        case update
    }
}
