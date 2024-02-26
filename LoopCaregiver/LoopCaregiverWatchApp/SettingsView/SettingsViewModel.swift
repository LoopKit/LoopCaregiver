//
//  SettingsViewModel.swift
//  LoopCaregiverWatchApp
//
//  Created by Bill Gestrich on 1/2/24.
//

import Combine
import Foundation
import LoopCaregiverKit
import SwiftUI

class SettingsViewModel: ObservableObject {
    
    @Published var networkAvailable: Bool
    @Published var timer: Timer?
    
    init() {
        self.networkAvailable = false
        self.timer = createTimer()
        Task {
            await self.checkNetwork()
        }
    }
    
    @MainActor
    func updateNetworkAvailable(available: Bool) {
        self.networkAvailable = available
    }
    
    private func createTimer() -> Timer {
        let timer = Timer(timeInterval: 30, repeats: true, block: { _ in
            Task {
                await self.checkNetwork()
            }
        })
        RunLoop.main.add(timer, forMode: .default)
        return timer
    }
    
    private func checkNetwork() async {
        do {
            guard let url = URL(string: "https://www.google.com") else { return }
            guard let (_, response) = try await URLSession.shared.data(from: url) as? (Data, HTTPURLResponse) else {
                await self.updateNetworkAvailable(available: false)
                return
            }
            let responseValid = response.statusCode >= 200 && response.statusCode <= 299
            await self.updateNetworkAvailable(available: responseValid)
        } catch {
            await self.updateNetworkAvailable(available: false)
        }
    }
    
    
    deinit {
        self.timer?.invalidate()
    }
    
}


protocol SettingsViewModelDelegate {
}
