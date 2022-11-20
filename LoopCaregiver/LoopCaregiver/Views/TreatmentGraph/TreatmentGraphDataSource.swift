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
    
    @Published var lastUpdateDate: Date = Date()
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
        nightscoutDataSource.$lastUpdate.sink(receiveValue: { [weak self] lastEGVUpdate in
            self?.updateGraphItems()
        })
        .store(in: &subscribers)
    }

    func updateGraphItems(){
        let egvs = nightscoutDataSource.egvs
        graphItems = egvs.map({$0.graphItem()})
        bolusEntryGraphItems = nightscoutDataSource.bolusEntries.map({$0.graphItem(egvValues: egvs)})
        carbEntryGraphItems = nightscoutDataSource.carbEntries.map({$0.graphItem(egvValues: egvs)})
        lastUpdateDate = Date()
    }
    
    func nowDate() -> Date {
        return Date()
    }
    
}

