//
//  LatestGlucoseInlineView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 1/2/24.
//

import HealthKit
import LoopKit
import SwiftUI


public struct LatestGlucoseInlineView: View {

    public let viewModel: WidgetViewModel
    
    public init(viewModel: WidgetViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            Text(statusText)
                .strikethrough(viewModel.isGlucoseStale)
                .font(.headline)
                .bold()
            if let currentTrendImageName = viewModel.currentTrendImageName {
                Image(systemName: currentTrendImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 15)
                    .offset(.init(width: 0.0, height: -7.0))
            }
        }
    }
    
    var statusText: String {
        var result = [String]()
        result.append(viewModel.currentGlucoseText)
        if !viewModel.currentGlucoseDateText.isEmpty {
            result.append("(\(viewModel.currentGlucoseDateText))")
        }
        return result.joined(separator: " ")
    }
}

struct LatestGlucoseInlineView_Previews: PreviewProvider {
    static var previews: some View {
        let latestGlucose = NewGlucoseSample(date: Date(), quantity: .init(unit: .gramsPerUnit, doubleValue: 1.0), condition: .aboveRange, trend: .down, trendRate: .none, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "12345")
        let viewModel = WidgetViewModel(timelineEntryDate: Date(), latestGlucose: latestGlucose, lastGlucoseChange: 3, isLastEntry: true, glucoseDisplayUnits: .gramsPerUnit)
        LatestGlucoseInlineView(viewModel: viewModel)
    }
}
