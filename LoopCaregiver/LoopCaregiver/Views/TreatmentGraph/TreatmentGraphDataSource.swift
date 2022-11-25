//
//  TreatmentGraphDataSource.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import Foundation
import NightscoutClient
import Combine
import LoopKit
import HealthKit

struct TreatmentGraphConfiguration {
    let graphTotalDays = 3
    let daysPerVisbleScrollFrame = 0.3
    let graphTag = 1000
}

class TreatmentGraphDataSource: ObservableObject {
    
    @Published var graphItems: [GraphItem] = []
    @Published var bolusEntryGraphItems: [GraphItem] = []
    @Published var carbEntryGraphItems: [GraphItem] = []
    @Published var glucoseDisplayUnits: HKUnit

    private let remoteDataSource: RemoteDataServiceManager
    private let settings: CaregiverSettings
    private let configuration = TreatmentGraphConfiguration()
  
    private var subscribers: Set<AnyCancellable> = []
    
    init(remoteDataSource: RemoteDataServiceManager, settings: CaregiverSettings) {
        self.remoteDataSource = remoteDataSource
        self.settings = settings
        self.glucoseDisplayUnits = settings.glucoseDisplayUnits
        self.startMonitoring()
    }
    
    func startMonitoring() {
        
        settings.$glucoseDisplayUnits.sink(receiveValue: { [weak self] displayUnits in
            guard let self else {return}
            self.glucoseDisplayUnits = displayUnits
            self.updateAll()
        })
        .store(in: &subscribers)

        remoteDataSource.$egvs.sink(receiveValue: { [weak self] glucoseSamples in
            guard let self else {return}
            self.updateGraphItems(glucoseSamples: glucoseSamples)
        })
        .store(in: &subscribers)
        
        remoteDataSource.$bolusEntries.sink(receiveValue: { [weak self] bolusEntries in
            guard let self else {return}
            self.updateBolusEntries(bolusEntries: bolusEntries)
        })
        .store(in: &subscribers)
        
        remoteDataSource.$carbEntries.sink(receiveValue: { [weak self] carbEntries in
            guard let self else {return}
            self.updateCarbEntries(carbEntries: carbEntries)
        })
        .store(in: &subscribers)
    }
    
    func updateAll() {
        updateGraphItems(glucoseSamples: remoteDataSource.egvs)
        updateBolusEntries(bolusEntries: remoteDataSource.bolusEntries)
        updateCarbEntries(carbEntries: remoteDataSource.carbEntries)
    }
    
    func updateGraphItems(glucoseSamples: [NewGlucoseSample]) {
        self.graphItems = glucoseSamples.map({$0.graphItem(displayUnit: CaregiverSettings().glucoseDisplayUnits)})
    }
    
    func updateBolusEntries(bolusEntries: [WGBolusEntry]){
        self.bolusEntryGraphItems = bolusEntries.map({$0.graphItem(egvValues: self.graphItems, displayUnit: CaregiverSettings().glucoseDisplayUnits)})
    }
    
    func updateCarbEntries(carbEntries: [WGCarbEntry]){
        self.carbEntryGraphItems = carbEntries.map({$0.graphItem(egvValues: self.graphItems, displayUnit: CaregiverSettings().glucoseDisplayUnits)})
    }
}

