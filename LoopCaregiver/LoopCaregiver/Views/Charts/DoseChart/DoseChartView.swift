//
//  DoseChartView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/26/22.
//

import HealthKit
import SwiftUI
import LoopKit
import LoopKitUI
import LoopUI

struct DoseChartView: UIViewRepresentable {
    
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @StateObject var viewModel = IOBContainerViewModel()
    var targetGlucoseSchedule: GlucoseRangeSchedule?
    var preMealOverride: TemporaryScheduleOverride?
    var scheduleOverride: TemporaryScheduleOverride?
    var dateInterval: DateInterval
    @Binding var isInteractingWithChart: Bool
    
    func makeUIView(context: Context) -> ChartContainerView {
        let view = ChartContainerView()
        view.chartGenerator = { frame in
            viewModel.chartManager.chart(atIndex: 0, frame: frame)?.view
        }
        
        let gestureRecognizer = UILongPressGestureRecognizer()
        gestureRecognizer.minimumPressDuration = 0.1
        gestureRecognizer.addTarget(context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        viewModel.chartManager.gestureRecognizer = gestureRecognizer
        view.addGestureRecognizer(gestureRecognizer)
        
        return view
    }
    
    func updateUIView(_ chartContainerView: ChartContainerView, context: Context) {
        viewModel.chartManager.invalidateChart(atIndex: 0)
        viewModel.chartManager.startDate = dateInterval.start
        viewModel.chartManager.maxEndDate = dateInterval.end
        viewModel.chartManager.updateEndDate(dateInterval.end)
        doseChart.doseEntries = bolusDoseEntries() + basalDoseEntries()
        viewModel.chartManager.prerender()
        chartContainerView.reloadChart()
    }
    
    func bolusDoseEntries() -> [DoseEntry] {
        let bolusEntries = remoteDataSource.bolusEntries
        let bolusDoseEntries = bolusEntries.map({DoseEntry(type: .bolus, startDate: $0.date, value: Double($0.amount), unit: .units)})
        return bolusDoseEntries
    }
    
    func basalDoseEntries() -> [DoseEntry] {
        let basalEntries = remoteDataSource.basalEntries.filter({$0.date >= dateInterval.start})
        let basalDoseEntries = basalEntries.map({DoseEntry(type: .tempBasal, startDate: $0.date, endDate: $0.date.addingTimeInterval(Double($0.duration * 60)), value: Double($0.rate), unit: .unitsPerHour, scheduledBasalRate: scheduledBasalRate(date: $0.date))})
        return basalDoseEntries
    }
    
    func scheduledBasalRate(date: Date) -> HKQuantity? {
        guard let scheduledBasalRatePeriod = getBasalRatePeriods().first(where: {$0.includesDate(date)}) else {
            return nil
        }
        return HKQuantity(unit: .internationalUnitsPerHour, doubleValue: scheduledBasalRatePeriod.rate)
    }
    
    func getBasalRatePeriods() -> [BasalRatePeriod] {
        let profiles = remoteDataSource.profiles
        let latestProfile = profiles.sorted(by: {$0.startDate < $1.startDate}).last
        
        guard let basals = latestProfile?.store?.Default.basal else {
            return []
        }
        
        var basalPeriods = [BasalRatePeriod]()
        
        for (index, basal) in basals.enumerated() {
            
            if index == 0 {
                continue
            }
            
            let lastBasal = basals[index - 1]
            basalPeriods.append(BasalRatePeriod(startSeconds: lastBasal.timeAsSeconds, durationSeconds: basal.timeAsSeconds - lastBasal.timeAsSeconds, rate: lastBasal.value))
        }
        
        if basalPeriods.count > 0 {
            let lastBasal = basals.last!
            basalPeriods.append(BasalRatePeriod(startSeconds: lastBasal.timeAsSeconds, durationSeconds: 86400 - lastBasal.timeAsSeconds, rate: lastBasal.value))
        }
        
        return basalPeriods
    }
    
    var doseChart: DoseChart {
        guard viewModel.chartManager.charts.count == 1, let iosChart = viewModel.chartManager.charts.first as? DoseChart else {
            fatalError("Expected exactly one iob chart in ChartsManager")
        }
        
        return iosChart
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator {
        var parent: DoseChartView
        
        init(_ parent: DoseChartView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
            case .began:
                withAnimation(.easeInOut(duration: 0.2)) {
                    parent.isInteractingWithChart = true
                }
            case .cancelled, .ended, .failed:
                // Workaround: applying the delay on the animation directly does not delay the disappearance of the touch indicator.
                // FIXME: No animation is applied to the disappearance of the touch indicator; it simply disappears.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self?.parent.isInteractingWithChart = false
                    }
                }
            default:
                break
            }
        }
    }
}

class IOBContainerViewModel: ObservableObject {
    let chartManager: ChartsManager = {
        let doseChart = DoseChart()
        return ChartsManager(colors: .primary, settings: .default, charts: [doseChart], traitCollection: UITraitCollection())
    }()
}

struct BasalRatePeriod {
    let startSeconds: Int
    let durationSeconds: Int
    let rate: Double
    
    func includesDate(_ date: Date) -> Bool {
        let midnight = Calendar.current.startOfDay(for: date)
        let startDate = midnight.addingTimeInterval(Double(startSeconds))
        let endDate = startDate.addingTimeInterval(Double(durationSeconds))
        return date >= startDate && date <= endDate
    }
    
    func description() -> String {
        return """
        -----
        Start: \(Double(startSeconds) / 60.0 / 60.0)
        End: \((Double(startSeconds) + Double(durationSeconds)) / 60.0 / 60.0)
        Rate: \(rate)
        -----
        """
    }
}
