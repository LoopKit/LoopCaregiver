//
//  NightscoutChartView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import Charts
import LoopKit
import HealthKit
import LoopKitUI
import Combine

struct NightscoutChartScrollView: View {
    
    @ObservedObject var settings: CaregiverSettings
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @State var scrollRequestSubject = PassthroughSubject<ScrollType, Never>()
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    static let timelineLookbackIntervals = [1, 3, 6, 12, 24]
    @AppStorage(UserDefaults.standard.timelineVisibleLookbackHoursKey) private var timelineVisibleLookbackHours = 6
    
    @State private var graphItemsInPopover: [GraphItem]? = nil
    
    private let configuration = NightscoutChartConfiguration()

    //TODO: Remove Disabled Zoom View Things
    @State private var lastScrollUpdate: Date? = nil
    private let minScale: CGFloat = 0.10
    private let maxScale: CGFloat = 3.0
    @State private var currentScale: CGFloat = 1.0
    
    @Environment(\.scenePhase) private var scenePhase
    
    func glucoseGraphItems() -> [GraphItem] {
        return remoteDataSource.glucoseSamples.map({$0.graphItem(displayUnit: settings.glucoseDisplayUnits)})
    }
    
    func predictionGraphItems() -> [GraphItem] {
        return remoteDataSource.predictedGlucose
            .map({$0.graphItem(displayUnit: settings.glucoseDisplayUnits)})
            .filter({$0.displayTime <= Date().addingTimeInterval(Double(timelinePredictionHours) * 60.0 * 60.0 )})
    }
    
    func bolusGraphItems() -> [GraphItem] {
        return remoteDataSource.bolusEntries
            .map({$0.graphItem(egvValues: glucoseGraphItems(), displayUnit: settings.glucoseDisplayUnits)})
    }
    
    func carbEntryGraphItems() -> [GraphItem] {
        return remoteDataSource.carbEntries
            .map({$0.graphItem(egvValues: glucoseGraphItems(), displayUnit: settings.glucoseDisplayUnits)})
    }

    func remoteCommandGraphItems() -> [GraphItem] {
        return remoteDataSource.recentCommands
            .compactMap({$0.graphItem(egvValues: glucoseGraphItems(), displayUnit: settings.glucoseDisplayUnits)})
    }
    
    var body: some View {
        GeometryReader { containerGeometry in
            ZoomableScrollView() { zoomScrollViewProxy in
                chartView
                    .chartOverlay { chartProxy in
                        GeometryReader { chartGeometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onTapGesture(count: 2) { tapLocation in
                                    switch timelineVisibleLookbackHours {
                                    case 6:
                                        updateTimelineHours(1)
                                    default:
                                        updateTimelineHours(6)
                                    }
                                    scrollRequestSubject.send(.contentPoint(tapLocation))
                                }
                                .onTapGesture(count: 1) { tapLocation in
                                    print("x pos: \(tapLocation.x)")
                                    if let (date, glucose) = chartProxy.value(at: tapLocation, as: (Date, Double).self) {
                                        let items = getNearbyGraphItems(date: date, value: glucose, chartProxy: chartProxy)
                                        
                                        guard items.count > 0 else { return }
                                            graphItemsInPopover = items
                                    }
                                }
                                .onReceive(scrollRequestSubject) { scrollType in
                                    let lookbackHours = CGFloat(totalGraphHours - timelinePredictionHours)
                                    let lookBackWidthRatio = lookbackHours / CGFloat(totalGraphHours)
                                    let axisWidth = chartGeometry.size.width - chartProxy.plotAreaSize.width
                                    let graphWithoutYAxisWidth = (containerGeometry.size.width * zoomLevel) - axisWidth
                                    let lookbackWidth = graphWithoutYAxisWidth * lookBackWidthRatio
                                    let focusedContentFrame = CGRect(x: 0, y: 0, width: lookbackWidth, height: containerGeometry.size.height)
                                    
                                    let request = ZoomScrollRequest(scrollType: scrollType, updatedFocusedContentFrame: focusedContentFrame, zoomAmount: zoomLevel)
                                    zoomScrollViewProxy.handleZoomScrollRequest(request)
                                }
                                .onChange(of: currentScale, perform: { newValue in
//                                    if let lastScrollUpdate, Date().timeIntervalSince(lastScrollUpdate) < 0.1 {
//                                        return
//                                    }
//                                    zoomScrollViewProxy.updateZoomKeepingCenter(newValue)
//                                    let centerPosition = CGPoint(x: chartGeometry.size.width / 2.0, y: 100.0)
//                                    zoomScrollViewProxy.updateZoom(newValue, centerPosition)
//                                    lastScrollUpdate = Date()
//                                    scrollRequestSubject.send(.scrollViewCenter)
                                })
                            //TODO: Remove Disabled Zoom View Things
                            //.modifier(PinchToZoom(minScale: 0.10, maxScale: 3.0, scale: $currentScale))
                        }
                    }
                    //TODO: Prefer leading/trailing of 10.0
                    //but that is causing graph centering
                    //issues
                    .padding(.init(top: 5, leading: 0, bottom: 0, trailing: 0)) //Top to prevent top Y label from clipping
                    .onChange(of: timelineVisibleLookbackHours) { newValue in
                        //This is to catch updates to the picker
                        scrollRequestSubject.send(.scrollViewCenter)
                    }
                    .onAppear(perform: {
                        scrollRequestSubject.send(.scrollViewCenter)
                        zoomScrollViewProxy.scrollTrailing()
                    })
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .active {
                            zoomScrollViewProxy.scrollTrailing()
                        }
                    }
            }
        }
        .popover(item: $graphItemsInPopover) { graphItemsInPopover in
            graphItemsPopoverView(graphItemsInPopover: graphItemsInPopover)
        }
    }
    
    var chartView: some View {
        
        Chart() {
            ForEach(glucoseGraphItems()){
                PointMark(
                    x: .value("Time", $0.displayTime),
                    y: .value("Reading", $0.value)
                )
                .foregroundStyle(by: .value("Reading", $0.colorType))
                .symbol(
                    FilledCircle()
                )
            }
            if settings.timelinePredictionEnabled {
                ForEach(predictionGraphItems()){
                    LineMark(
                        x: .value("Time", $0.displayTime),
                        y: .value("Reading", $0.value)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [7.0, 3.0]))
                    .foregroundStyle(Color(uiColor: .magenta.withAlphaComponent(0.5)))
                }   
            }
            ForEach(bolusGraphItems()) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", ColorType.clear))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
            ForEach(carbEntryGraphItems()) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", ColorType.clear))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
            ForEach(remoteCommandGraphItems()) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", ColorType.clear))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
        }
        //Make sure the domain values line up with what is in foregroundStyle above.
        .chartForegroundStyleScale(domain: ColorType.membersAsRange(), range: ColorType.allCases.map({$0.color}), type: .none)
        .chartXScale(domain: chartXRange())
        .chartYScale(domain: chartYRange())
        .chartXAxis{
            AxisMarks(position: .bottom, values: AxisMarkValues.automatic(desiredCount: totalAxisMarks, roundLowerBound: false, roundUpperBound: false)) { date in
                if let date = date.as(Date.self) {
                    AxisValueLabel(format: xAxisLabelFormatStyle(for:  date))
                } else {
                    AxisValueLabel(format: xAxisLabelFormatStyle(for: Date()))
                }
                AxisGridLine(centered: true)

            }
        }
//        .chartYAxis(.hidden)
    }
    
    func graphItemsPopoverView(graphItemsInPopover: [GraphItem]) -> some View {
        NavigationStack {
            List {
                ForEach (graphItemsInPopover) { item in
                    switch item.type {
                    case .bolus, .carb:
                        VStack {
                            HStack {
                                Text(item.displayTime, style: .time)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(item.type.presentableName)
                                    Text(item.formattedValue())
                                }
                            }
                            switch item.graphItemState {
                            case .error(let error):
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                            default:
                                EmptyView()
                            }
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .toolbar(content: {
                    Button {
                        self.graphItemsInPopover = nil
                    } label: {
                        Text("Done")
                    }
                
            })
        }
        .presentationDetents([.medium])
    }
    
    func updateTimelineHours(_ hours: Int) {
        timelineVisibleLookbackHours = hours
    }
    
    func getNearbyGraphItems(date: Date, value: Double, chartProxy: ChartProxy) -> [GraphItem] {
        
        func distanceCalcuator(graphItem: GraphItem, date: Date, value: Double) -> Double {
            
            guard let graphItemDatePosition = chartProxy.position(forX: graphItem.displayTime) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }
            
            guard let graphItemValuePosition = chartProxy.position(forY: graphItem.value) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }
            
            guard let tappedDatePosition = chartProxy.position(forX: date) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }
            
            guard let tappedValuePosition = chartProxy.position(forY: value) else {
                assertionFailure("Unexpected")
                return Double.infinity
            }
            
            return hypot(tappedDatePosition - graphItemDatePosition, tappedValuePosition - graphItemValuePosition)
        }
        
        let tappableGraphItems = allGraphItems().filter({ graphItem in
            switch graphItem.type {
            case .bolus, .carb:
                return true
            default:
                return false
            }
        })
        
        let sortedItems = tappableGraphItems.sorted(by: { item1, item2 in
            item1.displayTime < item2.displayTime
        }).filter({distanceCalcuator(graphItem: $0, date: date, value: value) < 20})
        
        if sortedItems.count <= 5 {
            return sortedItems
        } else {
            return Array(sortedItems[0...4])
        }
    }
    
    func allGraphItems() -> [GraphItem] {
        return remoteCommandGraphItems() + carbEntryGraphItems() + bolusGraphItems() + predictionGraphItems() + glucoseGraphItems()
    }
    
    func chartXRange() -> ClosedRange<Date> {
        let maxXDate = Date().addingTimeInterval(60 * 60 * TimeInterval(timelinePredictionHours))
        let minXDate = Date().addingTimeInterval(-60*60*TimeInterval(configuration.totalLookbackhours))
        return minXDate...maxXDate
    }
    
    var zoomLevel: Double {
        return CGFloat(totalGraphHours) / CGFloat(visibleFrameHours)
    }
    
    var timelinePredictionHours: Int {
        guard settings.timelinePredictionEnabled else {
            return 0
        }
        
        return min(6, timelineVisibleLookbackHours)
    }
    
    var totalGraphHours: Int {
        return configuration.totalLookbackhours + timelinePredictionHours
    }
    
    var visibleFrameHours: Int {
        return timelineVisibleLookbackHours + timelinePredictionHours
    }
    
    func chartYRange() -> ClosedRange<Double> {
        return chartYBase()...chartYTop()
    }
    
    func chartYBase() -> Double {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0).doubleValue(for: settings.glucoseDisplayUnits)
    }
    
    func chartYTop() -> Double {
        
        guard let maxGraphYValue = maxValueOfAllGraphItems() else {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 400).doubleValue(for: settings.glucoseDisplayUnits)
        }

        if maxGraphYValue >= 300 {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 400).doubleValue(for: settings.glucoseDisplayUnits)
        } else if maxGraphYValue >= 200 {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 300).doubleValue(for: settings.glucoseDisplayUnits)
        } else {
            return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 200).doubleValue(for: settings.glucoseDisplayUnits)
        }
    }
    
    func maxValueOfAllGraphItems() -> Double? {
        
        let maxBGY = self.glucoseGraphItems().max(by: {$0.value < $1.value})?.quantity.doubleValue(for: .milligramsPerDeciliter)
        var maxPredictedY: Double? = nil
        if settings.timelinePredictionEnabled {
            maxPredictedY = self.predictionGraphItems().max(by: {$0.value < $1.value})?.quantity.doubleValue(for: .milligramsPerDeciliter)
        }
        
        if let maxBGY = maxBGY, let maxPredictedY = maxPredictedY {
            return max(maxBGY, maxPredictedY)
        } else if let maxBGY = maxBGY {
            return maxBGY
        } else if let maxPredictedY = maxPredictedY {
            return maxPredictedY
        } else {
            return nil
        }
    }
    
    func formatGlucoseQuantity(_ quantity: HKQuantity) -> Double {
        return quantity.doubleValue(for: settings.glucoseDisplayUnits)
    }
    
    private var xAxisStride: Calendar.Component {
            return .minute
    }
     
     //How many minutes to skip (i.e. 1 is show every hour)
    private var xAxisStrideCount: Int {
        let visibleFrameMinutes = visibleFrameHours * 60
        let minutesPerInterval = visibleFrameMinutes / 6
        return minutesPerInterval
    }
    
    private var maxVisibleXLabels: Int {
        return 5
    }
    
    private var totalAxisMarks: Int {
        let result = totalGraphHours / visibleFrameHours * maxVisibleXLabels
        return result
    }
     
    private func xAxisLabelFormatStyle(for date: Date) -> Date.FormatStyle {
        switch visibleFrameHours {
        case 0..<2:
            return .dateTime.hour().minute()
        case 2..<4:
            return .dateTime.hour().minute()
        case 4..<6:
            return .dateTime.hour().minute()
        case 6..<12:
            return .dateTime.hour().minute()
        case 12..<24:
            return .dateTime.hour().minute()
        case 24...:
            return .dateTime.hour().minute()
        default:
            return .dateTime.hour().minute()
        }
    }
}

enum GraphItemType {
    case egv
    case predictedBG
    case bolus(Double)
    case carb(Int)
    
    var presentableName: String {
        switch self {
        case .egv:
            return "Glucose"
        case .predictedBG:
            return "Predicted Glucose"
        case .bolus:
            return "Bolus"
        case .carb:
            return "Carbs"
        }
    }
}

enum GraphItemState {
    case success
    case pending
    case error(LocalizedError)
}

//Required to use [GraphItem] to control popover visibility
extension [GraphItem]: Identifiable {
    public var id: String {
        var combinedUUID = ""
        for item in self {
            combinedUUID.append(item.id.uuidString)
        }
        return combinedUUID
    }
}

struct GraphItem: Identifiable, Equatable {
    
    var id = UUID()
    var type: GraphItemType
    var displayTime: Date
    var displayUnit: HKUnit
    var quantity: HKQuantity
    let graphItemState: GraphItemState
    
    var value: Double {
        return quantity.doubleValue(for: displayUnit)
    }
    
    var colorType: ColorType {
        return ColorType(quantity: quantity)
    }
    
    init(type: GraphItemType, displayTime: Date, quantity: HKQuantity, displayUnit: HKUnit, graphItemState: GraphItemState) {
        self.type = type
        self.displayTime = displayTime
        self.displayUnit = displayUnit
        self.quantity = quantity
        self.graphItemState = graphItemState
    }
    
    func annotationWidth() -> CGFloat {
        var width: CGFloat = 0.0
        switch self.type {
        case .bolus(let amount):
            width = CGFloat(amount) * 5.0
        case .carb(let amount):
            width = CGFloat(amount) * 0.5
        default:
            width = 0.5
        }
        
        let minWidth = 8.0
        let maxWidth = 50.0
        
        if width < minWidth {
            return minWidth
        } else if width > maxWidth {
            return maxWidth
        } else {
            return width
        }
    }
    
    func annotationHeight() -> CGFloat {
        return annotationWidth() //same
    }
    
    func fontSize() -> Double {
        
        var size = 0.0
        switch self.type {
        case .bolus(let amount):
            size = 3 * amount
        case .carb(let amount):
            size = Double(amount) / 2
        default:
            size = 10
        }
        
        let minSize = 8.0
        let maxSize = 12.0
        
        if size < minSize {
            return minSize
        } else if size > maxSize {
            return maxSize
        } else {
            return size
        }
    }
    
    func annotationFillStyle() -> TreatmentAnnotationView.HalfFilledAnnotationView.FillStyle {
        switch self.type {
        case .bolus:
            return .bottomFill
        case .carb:
            return .topFill
        default:
            return .fullFill
        }
    }
    
    func annotationFillColor() -> AnnotationColorStyle {
        switch self.type {
        case .bolus:
            return .blue
        case .carb:
            return .brown
        default:
            return .black
        }
    }
    
    func formattedValue() -> String {
        switch self.type {
        case .bolus(let amount):
            
            var maxFractionalDigits = 0
            if amount > 1 {
                maxFractionalDigits = 1
            } else {
                maxFractionalDigits = 2
            }
            
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = maxFractionalDigits
            formatter.numberStyle = .decimal
            let bolusQuantityString = formatter.string(from: amount as NSNumber) ?? ""
            return bolusQuantityString + "u"
        case .carb(let amount):
            return "\(amount)g"
        case .egv:
            return "\(self.value)"
        case .predictedBG:
            return "\(self.value)"
        }
    }
    
    func annotationLabelPosition() -> GraphItemLabelPosition {
        switch self.type {
        case .bolus:
            return .bottom
        case .carb:
            return .top
        default:
            return .top
        }
    }
    
    func shouldShowLabel() -> Bool {
        switch self.type {
        case .bolus:
            return true
        default:
            return true
        }
    }
    
    enum GraphItemLabelPosition {
        case top
        case bottom
    }
    
    
    //Equatable
    
    static func == (lhs: GraphItem, rhs: GraphItem) -> Bool {
        return lhs.id == rhs.id
    }
}

enum AnnotationColorStyle {
    case brown
    case blue
    case red
    case yellow
    case black
    case clear
    
    func color(scheme: ColorScheme) -> Color {
        switch self {
        case .brown:
            if scheme == .dark {
                return .white
            } else {
                return Color(.sRGB ,red: 0.7, green: 0.6, blue: 0.5)
            }
        case .blue:
            return .blue
        case .red:
            return .red
        case .yellow:
            return .yellow
        case .black:
            return .black
        case .clear:
            return .clear
        }
    }
}


enum ColorType: Int, Plottable, CaseIterable, Comparable {
    
    var primitivePlottable: Int {
        return self.rawValue
    }
    
    typealias PrimitivePlottable = Int
    
    case gray
    case green
    case yellow
    case red
    case clear
    
    init?(primitivePlottable: Int){
        self.init(rawValue: primitivePlottable)
    }
    
    init(quantity: HKQuantity) {
        let glucose = quantity.doubleValue(for:.milligramsPerDeciliter)
        switch glucose {
        case 0..<55:
            self = ColorType.red
        case 55..<70:
            self = ColorType.yellow
        case 70..<180:
            self = ColorType.green
        case 180..<250:
            self = ColorType.yellow
        case 250...:
            self = ColorType.red
        default:
            assertionFailure("Unexpected quantity: \(quantity)")
            self = ColorType.gray
        }
    }
    
    var color: Color {
        switch self {
        case .gray:
            return Color.gray
        case .green:
            return Color.green
        case .yellow:
            return Color.yellow
        case .red:
            return Color.red
        case .clear:
            return Color.clear
        }
    }
    
    static func membersAsRange() -> ClosedRange<ColorType> {
        return ColorType.allCases.first!...ColorType.allCases.last!
    }
    
    //Comparable
    static func < (lhs: ColorType, rhs: ColorType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}

func interpolateEGVValue(egvs: [GraphItem], atDate date: Date ) -> Double {
    
    switch egvs.count {
    case 0:
        return 0
    case 1:
        return egvs[0].value
    default:
        let priorEGVs = egvs.filter({$0.displayTime < date})
        guard let greatestPriorEGV = priorEGVs.last else {
            //All after, use first
            return egvs.first!.value
        }
        
        let laterEGVs = egvs.filter({$0.displayTime > date})
        guard let leastFollowingEGV = laterEGVs.first else {
            //All prior, use last
            return egvs.last!.value
        }
        
        return interpolateYValueInRange(yRange: (y1: greatestPriorEGV.value, y2: leastFollowingEGV.value), referenceXRange: (x1: greatestPriorEGV.displayTime, x2: leastFollowingEGV.displayTime), referenceXValue: date)
    }
}

//Given a known value x in a range (x1, x2), interpolate value y, in range (y1, y2)
func interpolateYValueInRange(yRange: (y1: Double, y2: Double), referenceXRange: (x1: Date, x2: Date), referenceXValue: Date) -> Double {
    let referenceRangeDistance = referenceXRange.x2.timeIntervalSince1970 - referenceXRange.x1.timeIntervalSince1970
    let lowerRangeToValueDifference = referenceXValue.timeIntervalSince1970 - referenceXRange.x1.timeIntervalSince1970
    let scaleFactor = lowerRangeToValueDifference / referenceRangeDistance
    
    let rangeDifference = abs(yRange.y1 - yRange.y2)
    return yRange.y1 + (rangeDifference * scaleFactor)
    
}

struct NightscoutChartConfiguration {
    let totalLookbackhours: Int = 24
    let graphTag = 1000
}

struct FilledCircle: Shape, ChartSymbolShape {
    var perceptualUnitRect: CGRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.scaledBy(0.55))
        return path
    }
}
