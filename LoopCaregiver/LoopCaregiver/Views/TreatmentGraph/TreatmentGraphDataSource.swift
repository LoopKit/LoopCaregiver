//
//  TreatmentGraphDataSource.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import Foundation
import NightscoutClient
import Combine

struct TreatmentGraphConfiguration {
    let graphTotalDays = 3
    let daysPerVisbleScrollFrame = 0.3
    let graphTag = 1000
}

class TreatmentGraphDataSource: ObservableObject {
    
    @Published var graphItems: [GraphItem] = []
    @Published var bolusEntryGraphItems: [GraphItem] = []
    @Published var carbEntryGraphItems: [GraphItem] = []

    private let nightscoutDataSource: NightscoutDataSource
    private let configuration = TreatmentGraphConfiguration()
  
    private var subscribers: Set<AnyCancellable> = []

    
    init(nightscoutDataSource: NightscoutDataSource) {
        self.nightscoutDataSource = nightscoutDataSource
        self.startMonitoring()
    }
    
    func startMonitoring() {
        
        nightscoutDataSource.$egvs.sink(receiveValue: { [weak self] egvs in
            guard let self else {return}
            self.graphItems = egvs.map({$0.graphItem()})
        })
        .store(in: &subscribers)
        
        nightscoutDataSource.$bolusEntries.sink(receiveValue: { [weak self] bolusEntries in
            guard let self else {return}
            self.bolusEntryGraphItems = bolusEntries.map({$0.graphItem(egvValues: self.nightscoutDataSource.egvs)})
        })
        .store(in: &subscribers)
        
        nightscoutDataSource.$carbEntries.sink(receiveValue: { [weak self] carbEntries in
            guard let self else {return}
            self.carbEntryGraphItems = carbEntries.map({$0.graphItem(egvValues: self.nightscoutDataSource.egvs)})
        })
        .store(in: &subscribers)
    }
}

