//
//  HUDView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import SwiftUI
import NightscoutClient
import Combine
import LoopKit

struct HUDView: View {
    
    @ObservedObject var hudViewModel: HUDViewModel
    @ObservedObject var nightscoutDateSource: RemoteDataServiceManager
    
    static let nowDate: () -> Date = {Date()}
    
    init(looperService: LooperService){
        self.hudViewModel = HUDViewModel(selectedLooper: looperService.looper, accountService: looperService.accountService)
        self.nightscoutDateSource = looperService.remoteDataSource
    }
    
    var body: some View {
        VStack {
            HStack (alignment: .center) {
                Text(formatEGV(nightscoutDateSource.currentEGV))
                    .font(.largeTitle)
                    .foregroundColor(egvValueColor())
                    .padding([.leading])
                if let egv = nightscoutDateSource.currentEGV {
                    Image(systemName: arrowImageName(egv: egv))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20.0)
                        .foregroundColor(egvValueColor())
                }
                VStack {
                    Text(lastEGVTimeFormatted())
                        .font(.footnote)
                    Text(lastEGVDeltaFormatted())
                        .font(.footnote)
                }
                Spacer()
                if nightscoutDateSource.updating {
                    ProgressView()
                }
                Picker("Looper", selection: $hudViewModel.selectedLooper) {
                    ForEach(hudViewModel.loopers()) { looper in
                        Text(looper.name).tag(looper)
                    }
                }
            }

        }
    }
    
    func arrowImageName(egv: NewGlucoseSample) -> String {
    
        guard let trendRate = egv.trendRate else {
            return "questionmark"
        }
        
        guard let trend = EGVTrend(rawValue: Int(trendRate.doubleValue(for: .milligramsPerDeciliter))) else { //TODO: Could crash on large values
            return "questionmark"
        }
        
        switch trend {
            
        case .doubleUp:
            return "arrow.up"
        case .singleUp:
            return  "arrow.up"
        case .fortyFiveUp:
            return  "arrow.up.forward"
        case .flat:
            return  "arrow.right"
        case .fortyFiveDown:
            return  "arrow.down.forward"
        case .singleDown:
            return  "arrow.down"
        case .doubleDown:
            return  "arrow.down"
        case .nonComputable:
            return  "questionmark"
        case .outOfRange:
            return  "questionmark"
        }
    }
    
    func lastEGVChange() -> Int? {
        let egvs = nightscoutDateSource.egvs
        guard egvs.count > 1 else {
            return nil
        }
        
        return egvs[egvs.count - 1].intValue() - egvs[egvs.count - 2].intValue()
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = nightscoutDateSource.currentEGV {
            let quantity = Int(currentEGV.intValue())
            return ColorType(egvValue: quantity).color
        } else {
            return .white
        }
    }
    
    func formatEGV(_ egv: NewGlucoseSample?) -> String {
        if let egv {
            return String(egv.presentableStringValue())
        } else {
            return " " //Using spaces, rather than a characterless String, to avoid view elements from jumping during load.
        }
    }
    
    func lastEGVTimeFormatted() -> String {
        guard let currentEGV = self.nightscoutDateSource.currentEGV else {
            return ""
        }
        
        return currentEGV.date.formatted(.dateTime.hour().minute())
    }
    
    func lastEGVDeltaFormatted() -> String {
        
        guard let lastEGVChange = self.lastEGVChange() else {
            return ""
        }
        
        if lastEGVChange > 0 {
            return "+\(lastEGVChange)"
        } else if lastEGVChange < 0 {
            return "\(lastEGVChange)"
        } else {
            return ""
        }
    }
    
    enum EGVTrend: Int {
        case doubleUp = 1
        case singleUp = 2
        case fortyFiveUp = 3
        case flat = 4
        case fortyFiveDown = 5
        case singleDown = 6
        case doubleDown = 7
        case nonComputable = 8
        case outOfRange = 9
    }
    
    func arrowForTrend(rawValue: Int?) -> String {
        guard let rawValue, let egvTrend = EGVTrend(rawValue: rawValue) else {
            return "?"
        }
        
        switch egvTrend {
        case .doubleUp:
            return ""
        default:
            return ""
        }
    }
}

class HUDViewModel: ObservableObject {
    
    @Published var selectedLooper: Looper {
        didSet {
            do {
                try accountService.updateActiveLoopUser(selectedLooper)
            } catch {
                print(error)
            }
        }
    }
    @ObservedObject var accountService: AccountServiceManager
    private var subscribers: Set<AnyCancellable> = []
    
    init(selectedLooper: Looper, accountService: AccountServiceManager) {
        self.selectedLooper = selectedLooper
        self.accountService = accountService
        
        self.accountService.$selectedLooper.sink { val in
        } receiveValue: { [weak self] updatedUser in
            if let self, let updatedUser, self.selectedLooper != updatedUser {
                self.selectedLooper = updatedUser
            }
        }.store(in: &subscribers)
    }
    
    func loopers() -> [Looper] {
        return accountService.loopers
    }
}
