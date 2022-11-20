//
//  HUDView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import SwiftUI
import NightscoutClient
import Combine

struct HUDView: View {
    
    @ObservedObject var hudViewModel: HUDViewModel
    @ObservedObject var nightscoutDateSource: NightscoutDataSource
    
    static let nowDate: () -> Date = {Date()}
    
    init(looperService: LooperService, selectedLooper: Looper){
        self.hudViewModel = HUDViewModel(selectedLooper: selectedLooper, looperService: looperService)
        self.nightscoutDateSource = selectedLooper.nightscoutDataSource
    }
    
    var body: some View {
        HStack {
            Text(formatEGV(nightscoutDateSource.currentEGV))
                .font(.largeTitle)
                .foregroundColor(egvValueColor())
                .padding()
            Spacer()
            Picker("Looper", selection: $hudViewModel.selectedLooper) {
                ForEach(hudViewModel.loopers()) { looper in
                    Text(looper.name).tag(looper)
                }
            }
        }
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = nightscoutDateSource.currentEGV {
            return ColorType(egvValue: currentEGV.value).color
        } else {
            return .white
        }
    }
    
    func formatEGV(_ egv: NightscoutEGV?) -> String {
        if let egv {
            return String(egv.value)
        } else {
            return " " //Using spaces, rather than a characterless String, to avoid view elements from jumping during load.
        }
    }

}

class HUDViewModel: ObservableObject {
    
    @Published var selectedLooper: Looper {
        didSet {
            do {
                try looperService.updateActiveLoopUser(selectedLooper)
            } catch {
                print(error)
            }
        }
    }
    @ObservedObject var looperService: LooperService
    private var subscribers: Set<AnyCancellable> = []
    
    init(selectedLooper: Looper, looperService: LooperService) {
        self.selectedLooper = selectedLooper
        self.looperService = looperService
        
        self.looperService.$selectedLooper.sink { val in
        } receiveValue: { [weak self] updatedUser in
            if let self, let updatedUser, self.selectedLooper != updatedUser {
                self.selectedLooper = updatedUser
            }
        }.store(in: &subscribers)
    }
    
    func loopers() -> [Looper] {
        return looperService.loopers
    }
}
