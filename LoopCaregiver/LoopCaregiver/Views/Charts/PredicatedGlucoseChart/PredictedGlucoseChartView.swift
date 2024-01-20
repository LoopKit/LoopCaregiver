//
//  PredictedGlucoseChartView.swift
//  Loop
//
//  Created by Michael Pangburn on 7/22/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopCaregiverKit
import LoopKit
import LoopKitUI
import SwiftUI

struct PredictedGlucoseChartView: UIViewRepresentable {
    
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @ObservedObject var settings: CaregiverSettings
    @StateObject var viewModel = PredictedGlucoseContainerViewModel()
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
        predictedGlucoseChart.glucoseUnit = settings.glucoseDisplayUnits
        predictedGlucoseChart.targetGlucoseSchedule = targetGlucoseSchedule
        predictedGlucoseChart.preMealOverride = preMealOverride
        predictedGlucoseChart.scheduleOverride = scheduleOverride
        predictedGlucoseChart.setGlucoseValues(remoteDataSource.glucoseSamples)
        predictedGlucoseChart.setPredictedGlucoseValues(remoteDataSource.predictedGlucose)
        viewModel.chartManager.prerender()
        chartContainerView.reloadChart()
    }

    var predictedGlucoseChart: PredictedGlucoseChart {
        guard viewModel.chartManager.charts.count == 1, let predictedGlucoseChart = viewModel.chartManager.charts.first as? PredictedGlucoseChart else {
            fatalError("Expected exactly one predicted glucose chart in ChartsManager")
        }

        return predictedGlucoseChart
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator {
        var parent: PredictedGlucoseChartView

        init(_ parent: PredictedGlucoseChartView) {
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

class PredictedGlucoseContainerViewModel: ObservableObject {
    let chartManager: ChartsManager = {
        let predictedGlucoseChart = PredictedGlucoseChart()
        return ChartsManager(colors: .primary, settings: .default, charts: [predictedGlucoseChart], traitCollection: UITraitCollection())
    }()
}
