//
//  PredicatedGlucoseContainerView.swift
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
    @StateObject var viewModel = PredicatedGlucoseContainerViewModel()
    @State private var isInteractingWithChart: Bool = false
    
    let displayGlucoseUnit = DisplayGlucoseUnitObservable(displayGlucoseUnit: CaregiverSetttings.glucoseUnits())
    
    init(remoteDataSource: RemoteDataServiceManager){
        self.remoteDataSource = remoteDataSource
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Glucose")
                    .bold()
                    .font(.subheadline)
                Spacer()
                if let eventualGlucose = remoteDataSource.predictedEGVs.last {
                    Text("Eventually \(eventualGlucose.presentableStringValueWithUnits())")
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
            PredictedGlucoseChartView(chartManager: self.viewModel.chartManager,
                                                  glucoseUnit: CaregiverSetttings.glucoseUnits(),
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
}


class PredicatedGlucoseContainerViewModel: ObservableObject {
    let chartManager: ChartsManager = {
        let predictedGlucoseChart = PredictedGlucoseChart()
        return ChartsManager(colors: .primary, settings: .default, charts: [predictedGlucoseChart], traitCollection: UITraitCollection())
    }()
}
