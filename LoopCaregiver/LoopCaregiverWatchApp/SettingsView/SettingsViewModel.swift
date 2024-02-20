//
//  SettingsViewModel.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 1/2/24.
//

import Combine
import Foundation
import LoopCaregiverKit
import Network
import SwiftUI

class SettingsViewModel: ObservableObject {
    
    let monitor: NWPathMonitor
    @Published var networkAvailable: Bool
    
    init() {
        self.networkAvailable = false
        self.monitor = NWPathMonitor()
        self.startNetworkMonitor()
    }
    
    func startNetworkMonitor() {
        let monitor = self.monitor
        Task { [weak self] in
            for await path in monitor {
                guard let self else { return }
                if path.status == .satisfied {
                    await self.updateNetworkAvailable(available: true)
                } else {
                    await self.updateNetworkAvailable(available: false)
                }
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    @MainActor
    func updateNetworkAvailable(available: Bool) {
        self.networkAvailable = available
    }
    
}


protocol SettingsViewModelDelegate {
}
