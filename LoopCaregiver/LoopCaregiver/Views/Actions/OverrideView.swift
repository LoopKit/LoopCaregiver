//
//  OverrideView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct OverrideView: View {
    
    let looperService: LooperService
    @Binding var showSheetView: Bool
    
    @State private var overidePresets: [NightscoutOverridePreset] = []
    @State private var overrideFromNightscout: NightscoutOverridePreset?
    @State private var pickerCurrentlySelectedOverride: NightscoutOverridePreset?
    @State private var loadingOverrides = true
    
    var body: some View {
        
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !loadingOverrides {
                        Picker("Overrides", selection: $pickerCurrentlySelectedOverride) {
                            Text("None").tag(nil as NightscoutOverridePreset?)
                            ForEach(overidePresets, id: \.self) { overrideValue in
                                //Auggie - adding the override symbol in the selector list
                                Text("\(overrideValue.symbol) \(overrideValue.name)").tag(overrideValue as NightscoutOverridePreset?)
                            }
                        }.pickerStyle(.wheel)
                            .labelsHidden()
                    } else {
                        ProgressView("Loading Overrides...")
                    }
                    Spacer()
                        .onAppear(perform: {
                            Task {
                                let profiles = try await looperService.remoteDataSource.getProfiles()
                                if let activeProfile = profiles.first, let loopSettings = activeProfile.loopSettings {
                                    overidePresets = loopSettings.overridePresets
                                    if let activeOverride = loopSettings.scheduleOverride {
                                        self.overrideFromNightscout = activeOverride
                                        self.pickerCurrentlySelectedOverride = activeOverride
                                    }
                                }
                                loadingOverrides = false
                            }
                        })
                }
                Spacer()
                Button("Update") {
                    Task {
                        guard let selectedOverride = pickerCurrentlySelectedOverride else {
                            let _ = try await looperService.remoteDataSource.cancelOverride()
                            showSheetView = false
                            return
                        }
                        
                        do {
                            //TODO: Set appropriate display symbol
                            //Auggie - respecting the override duration define in Loop
                            let _ = try await looperService.remoteDataSource.startOverride(overrideName: selectedOverride.name, overrideDisplay: "A", durationInMinutes: selectedOverride.durationInMinutes)
                            showSheetView = false
                        } catch {
                            //TODO: Show user error
                            print(error)
                        }
                        
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitle(Text("Custom Preset"), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                self.showSheetView = false
            }) {
                Text("Cancel")
            })
        }
    }
}

extension NightscoutOverridePreset: Hashable {
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public static func == (lhs: NightscoutOverridePreset, rhs: NightscoutOverridePreset) -> Bool {
        lhs.name == rhs.name
    }
    
    
}
