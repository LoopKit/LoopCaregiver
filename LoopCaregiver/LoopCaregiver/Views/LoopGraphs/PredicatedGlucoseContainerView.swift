//
//  GraphContainerView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/20/22.
//

import SwiftUI
import LoopKit
import LoopKitUI
import LoopUI
import SwiftCharts
import HealthKit
import NightscoutClient

struct PredicatedGlucoseContainerView: View {
    
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    
    private let chartManager: ChartsManager
    @State private var isInteractingWithChart: Bool = false
    
    let displayGlucoseUnit = DisplayGlucoseUnitObservable(displayGlucoseUnit: Self.glucoseUnits())
    
    init(remoteDataSource: RemoteDataServiceManager){
        self.chartManager = Self.createChartManager()
        self.remoteDataSource = remoteDataSource
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Glucose")
                    .bold()
                    .font(.subheadline)
                Spacer()
                if let eventualValue = remoteDataSource.predictedEGVs.last?.quantity {
                    Text("Eventually \(eventualValue) \(Self.glucoseUnits().unitString)")
                        .bold()
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }.opacity(isInteractingWithChart ? 0.0 : 1.0)
            .padding(.leading)
            predictedGlucoseChart
                .frame(height: 200.0)
        }

    }
    
    @ViewBuilder private var predictedGlucoseChart: some View {
        
        let hoursLookback = 1.0
        let hoursLookahead = 5.0
        
        if remoteDataSource.egvs.count > 0, remoteDataSource.predictedEGVs.count > 0 {
            PredictedGlucoseChartView(chartManager: self.chartManager,
                                                  glucoseUnit: Self.glucoseUnits(),
                                      glucoseValues: remoteDataSource.egvs,
                                      predictedGlucoseValues: remoteDataSource.predictedEGVs,
                                      targetGlucoseSchedule: nil,
                                      preMealOverride: nil,
                                      scheduleOverride: nil,
                                      dateInterval: DateInterval(start: Date().addingTimeInterval(60.0 * 60.0 * -hoursLookback), duration: 60.0 * 60.0 * hoursLookahead),
                                      isInteractingWithChart: $isInteractingWithChart)
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

extension NewGlucoseSample: GlucoseValue {
    public var startDate: Date {
        return date
    }

//    public var quantity: HKQuantity {
//        let minimum = 40
//        let maximum = 400
//        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(min(max(value, minimum), maximum)))
//    }
    
    
}
