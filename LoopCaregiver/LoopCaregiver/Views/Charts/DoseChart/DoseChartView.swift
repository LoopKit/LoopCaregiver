//
//  DoseChartView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/26/22.
//

import HealthKit
import LoopCaregiverKit
import LoopKit
import LoopKitUI
import SwiftUI

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
            .filter({$0.timestamp >= dateInterval.start})
            .sorted(by: {$0.timestamp < $1.timestamp})
        
        let bolusDoseEntries = bolusEntries.map({DoseEntry(type: .bolus, startDate: $0.timestamp, value: $0.amount, unit: .units)})
        return bolusDoseEntries
    }
    
    func basalDoseEntries() -> [DoseEntry] {
        
        let basalEntries = remoteDataSource.basalEntries
            .sorted(by: {$0.timestamp < $1.timestamp})
        
        var basalDoseEntries = [DoseEntry]()
        for (index, basalEntry) in basalEntries.enumerated() {

            var endDate = basalEntry.timestamp.addingTimeInterval(basalEntry.duration)
            
            if endDate > dateInterval.end {
                endDate = dateInterval.end
            }
            
            //Avoid overlapping basals
            let nextBasalIndex = index + 1
            if nextBasalIndex < basalEntries.count {
                let nextBasalEntry = basalEntries[nextBasalIndex]
                if nextBasalEntry.timestamp < endDate {
                    endDate = nextBasalEntry.timestamp
                }
            }

            let doseEntry = DoseEntry(type: .tempBasal, startDate: basalEntry.timestamp, endDate: endDate, value: basalEntry.rate, unit: .unitsPerHour, scheduledBasalRate: scheduledBasalRate(date: basalEntry.timestamp))
            basalDoseEntries.append(doseEntry)
        }
        
        basalDoseEntries = basalDoseEntries.filter({ dose in
            dose.endDate >= dateInterval.start
        })
            
        return basalDoseEntries
    }
    
    func scheduledBasalRate(date: Date) -> HKQuantity? {
        guard let scheduledBasalRatePeriod = getBasalRatePeriods().first(where: {$0.includesDate(date)}) else {
            return nil
        }
        return HKQuantity(unit: .internationalUnitsPerHour, doubleValue: scheduledBasalRatePeriod.rate)
    }
    
    func getBasalRatePeriods() -> [BasalRatePeriod] {
        
        guard let basals = remoteDataSource.currentProfile?.getDefaultProfile()?.basal else {
            return []
        }
        
        var basalPeriods = [BasalRatePeriod]()
        
        for (index, basal) in basals.enumerated() {
            
            if index == 0 {
                continue
            }
            
            let lastBasal = basals[index - 1]
            basalPeriods.append(BasalRatePeriod(startSeconds: lastBasal.offset, durationSeconds: basal.offset - lastBasal.offset, rate: lastBasal.value))
        }
        
        if basalPeriods.count > 0 {
            let lastBasal = basals.last!
            basalPeriods.append(BasalRatePeriod(startSeconds: lastBasal.offset, durationSeconds: 86400 - lastBasal.offset, rate: lastBasal.value))
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
    let startSeconds: TimeInterval
    let durationSeconds: TimeInterval
    let rate: Double
    
    func includesDate(_ date: Date) -> Bool {
        let midnight = Calendar.current.startOfDay(for: date)
        let startDate = midnight.addingTimeInterval(startSeconds)
        let endDate = startDate.addingTimeInterval(durationSeconds)
        return date >= startDate && date <= endDate
    }
    
    func description() -> String {
        return """
        -----
        Start: \(startSeconds / 60.0 / 60.0)
        End: \(startSeconds + durationSeconds / 60.0 / 60.0)
        Rate: \(rate)
        -----
        """
    }
}
