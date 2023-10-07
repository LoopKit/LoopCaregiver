//
//  OverrideView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutKit

struct OverrideView: View {
    
    @StateObject var viewModel = OverrideViewModel()
    var delegate: OverrideViewDelegate
    var deliveryCompleted: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            Spacer()
            pickerContainerView
            deliveryStatusContainerView
            Spacer()
            actionButton
        }
        .onAppear(perform: {
            Task {
                await viewModel.setup(delegate: delegate, deliveryCompleted: deliveryCompleted)
            }
        })
    }
    
    @ViewBuilder
    var pickerContainerView: some View {
        HStack {
            switch viewModel.overrideListState {
            case .loading:
                ProgressView("Loading Overrides...")
            case .loadingError(let error):
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
            case .loadingComplete(let overrideState):
                Picker("Overrides", selection: $viewModel.pickerSelectedOverride) {
                    ForEach(overrideState.availableOverrides, id: \.self) { overrideValue in
                        Text(overrideValue.presentableDescription()).tag(overrideValue as TemporaryScheduleOverride?)
                            .fontWeight(overrideValue == viewModel.activeOverride ? .heavy : .regular)
                    }
                }.pickerStyle(.wheel)
                    .labelsHidden()
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
}

class OverrideViewModel: ObservableObject, Identifiable {
    
    var delegate: OverrideViewDelegate? = nil
    var deliveryCompleted: (() -> Void)? = nil
    
    @Published var overrideListState: OverrideListState = .loading
    @Published var pickerSelectedOverride: TemporaryScheduleOverride?
    @Published var activeOverride: TemporaryScheduleOverride?
    @Published var lastDeliveryError: Error? = nil
    @Published var deliveryInProgress: Bool = false
    
    var actionButtonEnabled: Bool {
        readyForDelivery
    }
    
    var actionButtonType: ActionButtonType {
        if let pickerSelectedOverride = pickerSelectedOverride, pickerSelectedOverride == activeOverride {
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
                                                                       durationTime: selectedOverride.duration)
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
        
        OverrideView(viewModel: OverrideViewModel(), delegate: delegate)
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
        TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
        TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
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
}
