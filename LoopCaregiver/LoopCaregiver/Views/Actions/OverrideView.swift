//
//  OverrideView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutKit

struct OverrideView: View {
    
    let looperService: LooperService
    @Binding var showSheetView: Bool
    
    @State private var overidePresets: [TemporaryScheduleOverride] = []
    @State private var overrideFromNightscout: TemporaryScheduleOverride?
    @State private var pickerCurrentlySelectedOverride: TemporaryScheduleOverride?
    @State private var loadingOverrides = true
    @State private var errorText: String? = nil
    
    var body: some View {
        
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if loadingOverrides {
                        ProgressView("Loading Overrides...")
                    } else {
                        //TODO: Only show picker if overrides successfully loaded
                        Picker("Overrides", selection: $pickerCurrentlySelectedOverride) {
                            Text("None").tag(nil as TemporaryScheduleOverride?)
                            ForEach(overidePresets, id: \.self) { overrideValue in
                                Text(overrideValue.presentableDescription()).tag(overrideValue as TemporaryScheduleOverride?)
                            }
                        }.pickerStyle(.wheel)
                            .labelsHidden()
                    }
                    Spacer()
                }
                if let errorText {
                    Text(errorText)
                        .foregroundColor(.critical)
                }
                Spacer()
                //TODO: Disable button when overrides not successfully loaded
                //and show a reload button
                Button("Update") {
                    Task {
                        await activateSelectedOverride()
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
        .onAppear(perform: {
            Task {
                await loadOverrides()
            }
        })
    }
    
    func loadOverrides() async {
        overidePresets = looperService.remoteDataSource.currentProfile?.settings.overridePresets ?? []
        if let activeOverride = looperService.remoteDataSource.activeOverride() {
            self.overrideFromNightscout = activeOverride
            self.pickerCurrentlySelectedOverride = activeOverride
        }
        
        loadingOverrides = false
    }
    
    func activateSelectedOverride() async {
        
        errorText = nil
        
        do {
            if let selectedOverride = pickerCurrentlySelectedOverride {
                try await looperService.remoteDataSource.startOverride(overrideName: selectedOverride.name ?? "",
                                                                       durationTime: selectedOverride.duration)
            } else {
                try await looperService.remoteDataSource.cancelOverride()
            }
            
            showSheetView = false
        } catch {
            errorText = error.localizedDescription
        }
    }
}
