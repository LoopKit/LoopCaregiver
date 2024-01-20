//
//  COBChartView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/26/22.
//

import HealthKit
import LoopCaregiverKit
import LoopKit
import LoopKitUI
import SwiftUI


struct COBChartView: UIViewRepresentable {
    
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @StateObject var viewModel = COBContainerViewModel()
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
        let cobValues = remoteDataSource.carbEntries.map({CarbValue(startDate: $0.timestamp, value: Double($0.carbs))})
        cobChart.setCOBValues(cobValues)
        /*
         This will probably need to do something as done in:
            self.deviceManager.carbStore.getCarbsOnBoardValues(start: startDate, end: nil, effectVelocities: FeatureFlags.dynamicCarbAbsorptionEnabled ? state.insulinCounteractionEffects : nil) { (result) in
         */
//        cobChart.doseEntries = remoteDataSource.bolusEntries.map({DoseEntry(type: .bolus, startDate: $0.date, value: Double($0.amount), unit: .units)})
        viewModel.chartManager.prerender()
        chartContainerView.reloadChart()
    }

    var cobChart: COBChart {
        guard viewModel.chartManager.charts.count == 1, let iosChart = viewModel.chartManager.charts.first as? COBChart else {
            fatalError("Expected exactly one cob chart in ChartsManager")
        }

        return iosChart
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator {
        var parent: COBChartView

        init(_ parent: COBChartView) {
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

class COBContainerViewModel: ObservableObject {
    let chartManager: ChartsManager = {
        let doseChart = COBChart()
        return ChartsManager(colors: .primary, settings: .default, charts: [doseChart], traitCollection: UITraitCollection())
    }()
}
