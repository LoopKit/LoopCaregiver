//
//  LoopGraphTestView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/20/22.
//

import SwiftUI

//Loop
import LoopKit
import LoopKitUI
import LoopUI
import SwiftCharts
import HealthKit

import NightscoutClient

struct LoopGraphTestView: View {
    
    @ObservedObject var nightscoutDataSource: NightscoutDataSource
    
    private let chartManager: ChartsManager
    @State private var isInteractingWithChart: Bool = false
    
    let displayGlucoseUnit = DisplayGlucoseUnitObservable(displayGlucoseUnit: Self.glucoseUnits())
    
    init(nightscoutDataSource: NightscoutDataSource){
        self.chartManager = Self.createChartManager()
        self.nightscoutDataSource = nightscoutDataSource
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Glucose")
                    .bold()
                    .font(.subheadline)
                Spacer()
                if let eventualValue = nightscoutDataSource.predictedEGVs.last?.value {
                    Text("Eventually \(eventualValue) \(Self.glucoseUnits().unitString)")
                        .bold()
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            predictedGlucoseChart
        }

    }
    
    @ViewBuilder private var predictedGlucoseChart: some View {
        
        let hoursLookback = 1.0
        let hoursLookahead = 4.0
        
        if nightscoutDataSource.egvs.count > 0, nightscoutDataSource.predictedEGVs.count > 0 {

            PredictedGlucoseChartView(chartManager: self.chartManager,
                                                  glucoseUnit: Self.glucoseUnits(),
                                      glucoseValues: nightscoutDataSource.egvs,
                                      predictedGlucoseValues: nightscoutDataSource.predictedEGVs,
                                      targetGlucoseSchedule: nil,
                                      preMealOverride: nil,
                                      scheduleOverride: nil,
                                      dateInterval: DateInterval(start: Date().addingTimeInterval(60.0 * 60.0 * -hoursLookback), duration: 60.0 * 60.0 * hoursLookahead),
                                      isInteractingWithChart: $isInteractingWithChart)
            .frame(height: 200.0)
        } else {
         Text("")
        }
        

    }
    
    static func glucoseUnits() -> HKUnit {
        return .milligramsPerDeciliter
    }
    
    static func createChartManager() -> ChartsManager {
        let predictedGlucoseChart = PredictedGlucoseChart() //TODO: Will this get recreated too often?
        return ChartsManager(colors: .primary, settings: .default, charts: [predictedGlucoseChart], traitCollection: UITraitCollection())
    }
    
    
}



extension ChartSettings {
    static var `default`: ChartSettings {
        var settings = ChartSettings()
        settings.top = 12
        settings.bottom = 0
        settings.trailing = 8
        settings.axisTitleLabelsToLabelsSpacing = 0
        settings.labelsToAxisSpacingX = 6
        settings.clipInnerFrame = false
        return settings
    }
}

extension ChartColorPalette {
    static var primary: ChartColorPalette {
        return ChartColorPalette(axisLine: .axisLineColor, axisLabel: .axisLabelColor, grid: .gridColor, glucoseTint: .glucoseTintColor, insulinTint: .insulinTintColor)
    }
}

extension NightscoutEGV: GlucoseValue {
    public var startDate: Date {
        return systemTime
    }

    public var quantity: HKQuantity {
        let minimum = 40
        let maximum = 400
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(min(max(value, minimum), maximum)))
    }
    
    
}
