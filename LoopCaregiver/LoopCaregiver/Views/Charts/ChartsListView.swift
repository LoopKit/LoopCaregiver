//
//  ChartsListView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/26/22.
//

import LoopCaregiverKit
import LoopKitUI
import SwiftCharts
import SwiftUI

struct ChartsListView: View {
    
    let looperService: LooperService
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    
    @State var isInteractingWithPredictedChart: Bool = false
    @State var isInteractingWithActiveInsulinChart: Bool = false
    @State var isInteractingWithInsulinDeliveryChart: Bool = false
    @State var isInteractingWithActiveCarbsChart: Bool = false
    
    let chartHeight = 200.0
    
    var body: some View {
        VStack (spacing: 5.0) {
            ChartWrapperView(title:"Glucose", subtitle: eventualGlucose(), hideLabels: $isInteractingWithPredictedChart) {
                if remoteDataSource.glucoseSamples.count > 0 {
                    PredictedGlucoseChartView(remoteDataSource: remoteDataSource,
                                              settings: settings,
                                              targetGlucoseSchedule: nil,
                                              preMealOverride: nil,
                                              scheduleOverride: nil,
                                              dateInterval: loopGraphInterval,
                                              isInteractingWithChart: $isInteractingWithPredictedChart)
                } else {
                    Spacer()
                }
            }
            ChartWrapperView(title:"Active Insulin", subtitle: formattedIOB(), hideLabels: $isInteractingWithActiveInsulinChart) {
            }
            ChartWrapperView(title:"Insulin Delivery", subtitle: formattedInsulinDelivery(), hideLabels: $isInteractingWithInsulinDeliveryChart) {
                DoseChartView(remoteDataSource: remoteDataSource,
                              settings: settings,
                              targetGlucoseSchedule: nil,
                              preMealOverride: nil,
                              scheduleOverride: nil,
                              dateInterval: loopGraphInterval,
                              isInteractingWithChart: $isInteractingWithInsulinDeliveryChart)
            }
            .frame(maxHeight: 150.0)
            ChartWrapperView(title:"Active Carbohydrates", subtitle: formattedCOB(), hideLabels: $isInteractingWithActiveCarbsChart) {
                /*
                 if remoteDataSource.glucoseSamples.count > 0, remoteDataSource.predictedGlucose.count > 0 {
                 COBChartView(remoteDataSource: remoteDataSource,
                 settings: settings,
                 targetGlucoseSchedule: nil,
                 preMealOverride: nil,
                 scheduleOverride: nil,
                 dateInterval: loopGraphInterval,
                 isInteractingWithChart: $isInteractingWithActiveCarbsChart)
                 } else {
                 Spacer()
                 }
                 */
            }
            TimelineWrapperView(title:"Timeline", settings: settings) {
                HStack {
                    //Using .padding causes the chart overlay GeometryReader to
                    //have an offset that is the padding amount.
                    //Using a custom "padding" solution here with an HStack to avoid this.
                    Spacer(minLength: 10.0)
                    NightscoutChartScrollView(settings: looperService.settings, remoteDataSource: remoteDataSource)
                    Spacer(minLength: 10.0)
                }

            }
        }
    }
    
    var loopGraphInterval: DateInterval {
        let hoursLookback = 1.0
        let hoursLookahead = 5.0
        return DateInterval(start: Date().addingTimeInterval(60.0 * 60.0 * -hoursLookback), duration: 60.0 * 60.0 * hoursLookahead)
    }
    
    func eventualGlucose() -> String {
        
        guard let eventualGlucose = remoteDataSource.predictedGlucose.last else {
            return ""
        }
        
        return "Eventually \(eventualGlucose.presentableStringValueWithUnits(displayUnits: settings.glucoseDisplayUnits))"
    }
    
    func formattedCOB() -> String {
        guard let cob = remoteDataSource.currentCOB?.cob else {
            return ""
        }
        return String(format: "%.0f g", cob)
    }
    
    func formattedIOB() -> String {
        guard let iob = remoteDataSource.currentIOB?.iob else {
            return ""
        }
        
        var maxFractionalDigits = 0
        if iob > 1 {
            maxFractionalDigits = 1
        } else {
            maxFractionalDigits = 2
        }
        
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionalDigits
        formatter.numberStyle = .decimal
        let iobString = formatter.string(from: iob as NSNumber) ?? ""
        return iobString + " U Total"
    }
    
    func formattedInsulinDelivery() -> String {
        return "" //TODO: Implement this
    }
    
    
}


struct ChartWrapperView<ChartContent:View>: View {
    let title: String
    let subtitle: String
    @Binding var hideLabels: Bool
    let chartContent:ChartContent
    
    public init(title: String, subtitle: String, hideLabels: Binding<Bool>, @ViewBuilder chartContent: () -> ChartContent) {
        self.title = title
        self.subtitle = subtitle
        self._hideLabels = hideLabels
        self.chartContent = chartContent()
    }
    
    var body: some View {
        VStack {
            TitleSubtitleRowView(title: title, subtitle: subtitle)
            .opacity(hideLabels ? 0.0 : 1.0)
            chartContent
        }
    }
}


struct TimelineWrapperView<ChartContent:View>: View {

    let title: String
    @ObservedObject var settings: CaregiverSettings
    @AppStorage(UserDefaults.standard.timelineVisibleLookbackHoursKey) private var timelineVisibleLookbackHours = 6
    let lookbackIntervals = NightscoutChartScrollView.timelineLookbackIntervals
    let chartContent:ChartContent
    
    public init(title: String, settings: CaregiverSettings, @ViewBuilder chartContent: () -> ChartContent) {
        self.title = title
        self.settings = settings
        self.chartContent = chartContent()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .bold()
                    .font(.subheadline)
                    .padding([.leading], 10.0)
                Spacer()
                Picker("Range", selection: $timelineVisibleLookbackHours) {
                    ForEach(lookbackIntervals, id: \.self) { period in
                        Text("\(period)h").tag(period)
                    }
                }
            }
            chartContent
        }
    }
}

struct TitleSubtitleRowView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Text(title)
                .bold()
                .font(.subheadline)
                .padding([.leading], 10.0)
            Spacer()
            Text(subtitle)
                .foregroundColor(.gray)
                .bold()
                .font(.subheadline)
                .padding([.trailing], 10.0)
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
        return ChartColorPalette(axisLine: .axisLineColor, axisLabel: .axisLabelColor, grid: .gridColor, glucoseTint: .glucoseTintColor, insulinTint: .insulinTintColor, carbTint: .carbTintColor)
    }
}
