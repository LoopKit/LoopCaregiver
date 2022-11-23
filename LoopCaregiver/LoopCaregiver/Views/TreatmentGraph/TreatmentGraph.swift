//
//  TreatmentGraph.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import Charts
import NightscoutClient

struct TreatmentGraphScrollView: View {
    
    @ObservedObject var dataSource: TreatmentGraphDataSource
    private let graphTag = 1000
    private let configuration = TreatmentGraphConfiguration()
    
    init(looper: Looper) {
        self.dataSource = TreatmentGraphDataSource(nightscoutDataSource: looper.nightscoutDataSource)
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { sp in
                ScrollView (.horizontal) {
                    TreatmentGraph(dataSource: dataSource)
                        .frame(width: proxy.size.width * CGFloat(configuration.graphTotalDays) / configuration.daysPerVisbleScrollFrame)
                        .padding()
                        .id(graphTag)
                }
                .onChange(of: dataSource.graphItems, perform: { newValue in
                    sp.scrollTo(graphTag, anchor: .trailing)
                })
                .onAppear(perform: {
                    sp.scrollTo(graphTag, anchor: .trailing)
                })
            }
        }
    }
}

struct TreatmentGraph: View {
    
    @ObservedObject var dataSource: TreatmentGraphDataSource
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        Chart() {
            ForEach(dataSource.graphItems){
                PointMark(
                    x: .value("Time", $0.displayTime),
                    y: .value("Reading", $0.value)
                )
                .foregroundStyle(by: .value("Reading", $0.colorType))
            }
            ForEach(dataSource.bolusEntryGraphItems) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", graphItem.colorType))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
            ForEach(dataSource.carbEntryGraphItems) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", graphItem.colorType))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem)
                }
            }
        }
        //Make sure the domain values line up with what is in foregroundStyle above.
        .chartForegroundStyleScale(domain: ColorType.membersAsRange(), range: ColorType.allCases.map({$0.color}), type: .none)
        .chartYScale(domain: 40...400)
        .chartXAxis{
            AxisMarks(position: .bottom, values: .stride(by: xAxisStride, count: xAxisStrideCount)) { date in
                AxisValueLabel(format: xAxisLabelFormatStyle(for: date.as(Date.self) ?? Date()))
            }
        }
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle()) //For taps
                    .onTapGesture { tapPosition in
                        guard let (date, value) = proxy.value(at: tapPosition, as: (Date, Int).self) else {
                            print("Could not convert")
                            return
                        }
                        print("Location: \(date), \(value)")
                    }
            }
        }
    }
    

    //MARK: Experimental time range things
    
    //See https://mobile.blog/2022/07/04/an-adventure-with-swift-charts
    
    var timeRange: TimeRange {
        return .today
    }
    
    enum TimeRange {
        case today
        case thisWeek
        case thisMonth
        case thisYear
    }
    
    private var xAxisStride: Calendar.Component {
        switch timeRange {
        case .today:
            return .hour
        case .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        }
    }
     
    private var xAxisStrideCount: Int {
        switch timeRange {
        case .today:
            return 1
        case .thisWeek:
            return 1
        case .thisMonth:
            return 5
        case .thisYear:
            return 3
        }
    }
     
    private func xAxisLabelFormatStyle(for date: Date) -> Date.FormatStyle {
        switch timeRange {
        case .today:
            return .dateTime.hour()
        case .thisWeek, .thisMonth:
            if date == dataSource.graphItems.first?.displayTime {
                return .dateTime.month(.abbreviated).day(.twoDigits)
            }
            return .dateTime.day(.twoDigits)
        case .thisYear:
            return .dateTime.month(.abbreviated)
        }
    }
}

enum GraphItemType {
    case egv
    case bolus(WGBolusEntry)
    case carb(WGCarbEntry)
}

struct GraphItem: Identifiable, Equatable {
    
    var id = UUID()
    var type: GraphItemType
    var value: Int
    var displayTime: Date
    
    var colorType: ColorType {
        return ColorType(egvValue: value)
    }
    
    func annotationWidth() -> CGFloat {
        var width: CGFloat = 0.0
        switch self.type {
        case .bolus(let bolusEntry):
            width = CGFloat(bolusEntry.amount) * 5.0
        case .carb(let carbEntry):
            width = CGFloat(carbEntry.amount) * 0.5
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
        case .bolus(let bolusEntry):
            size = Double(3 * bolusEntry.amount)
        case .carb(let carbEntry):
            size = Double(carbEntry.amount / 2)
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
    func annotationFillColor() -> Color {
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
        case .bolus(let bolusEntry):
            if bolusEntry.amount - Float(Int(bolusEntry.amount)) >= 0.1 { //TODO: Crash risk
                return String(format:"%.1fu", bolusEntry.amount)
            } else {
                return String(format:"%.0fu", bolusEntry.amount)
            }
        case .carb(let carbEntry):
            return "\(carbEntry.amount)g"
        case .egv:
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

enum ColorType: Int, Plottable, CaseIterable, Comparable {
    
    var primitivePlottable: Int {
        return self.rawValue
    }
    
    typealias PrimitivePlottable = Int
    
    case gray
    case green
    case yellow
    case red
    
    init?(primitivePlottable: Int){
        self.init(rawValue: primitivePlottable)
    }
    
    init(egvValue: Int) {
        switch egvValue {
        case 0..<60:
            self = ColorType.red
        case 60..<80:
            self = ColorType.yellow
        case 80..<180:
            self = ColorType.green
        case 180...249:
            self = ColorType.yellow
        case 250...:
            self = ColorType.red
        default:
            assertionFailure("Uexpected range")
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



extension NightscoutEGV {
    func graphItem() -> GraphItem {
        return GraphItem(type: .egv, value: value, displayTime: displayTime)
    }
}

extension WGCarbEntry {
    
    func graphItem(egvValues: [NightscoutEGV]) -> GraphItem {
        let relativeEgvValue = interpolateEGVValue(egvs: egvValues, atDate: date) ?? 390
        return GraphItem(type: .carb(self), value: relativeEgvValue, displayTime: date)
    }
    
    func interpolateEGVValue(egvs: [NightscoutEGV], atDate date: Date ) -> Int? {
        
        guard egvs.count >= 2 else {
            return egvs.first?.value
        }
        
        let priorEGVs = egvs.filter({$0.displayTime < date})
        guard let greatestPriorEGV = priorEGVs.last else {
            //All after, use first
            return egvs.first?.value
        }
        
        let laterEGVs = egvs.filter({$0.displayTime > date})
        guard let leastFollowingEGV = laterEGVs.first else {
            //All prior, use last
            return egvs.last?.value
        }
        
        return interpolateRange(range: (first: greatestPriorEGV.value, second: leastFollowingEGV.value), referenceRange: (first: greatestPriorEGV.displayTime, second: leastFollowingEGV.displayTime), refereceValue: date)
    }
}

extension WGBolusEntry {
    
    func graphItem(egvValues: [NightscoutEGV]) -> GraphItem {
        let relativeEgvValue = interpolateEGVValue(egvs: egvValues, atDate: date) ?? 390
        return GraphItem(type: .bolus(self), value: relativeEgvValue, displayTime: date)
    }
}

func interpolateEGVValue(egvs: [NightscoutEGV], atDate date: Date ) -> Int? {
    
    guard egvs.count >= 2 else {
        return egvs.first?.value
    }
    
    let priorEGVs = egvs.filter({$0.displayTime < date})
    guard let greatestPriorEGV = priorEGVs.last else {
        //All after, use first
        return egvs.first?.value
    }
    
    let laterEGVs = egvs.filter({$0.displayTime > date})
    guard let leastFollowingEGV = laterEGVs.first else {
        //All prior, use last
        return egvs.last?.value
    }
    
    return interpolateRange(range: (first: greatestPriorEGV.value, second: leastFollowingEGV.value), referenceRange: (first: greatestPriorEGV.displayTime, second: leastFollowingEGV.displayTime), refereceValue: date)
}

func interpolateRange(range: (first: Int, second: Int), referenceRange: (first: Date, second: Date), refereceValue: Date) -> Int {
    let referenceRangeDistance = referenceRange.second.timeIntervalSince1970 - referenceRange.first.timeIntervalSince1970
    let lowerRangeToValueDifference = refereceValue.timeIntervalSince1970 - referenceRange.first.timeIntervalSince1970
    let scaleFactor = lowerRangeToValueDifference / referenceRangeDistance
    
    let rangeDifference = range.first - range.second
    return range.first + (rangeDifference * Int(scaleFactor))
    
}
