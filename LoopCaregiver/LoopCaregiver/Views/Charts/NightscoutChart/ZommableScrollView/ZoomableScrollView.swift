//
//  ZoomableScrollView.swift
//  ScrollViewDemo
//
//  Created by Bill Gestrich on 8/13/23.
//

import SwiftUI
import Combine

/*
 Terminology
 
 ScrollView: The view that manages your scrollable contentView - this is like a view port. Frame is often {0, 0, visibleWidth, visibleHeight}
 ContentView: Is your scrollable content. Frame  example: {-100, 0, 1000, 300}
 FocusedContent: The frame within ContentView that we will focus on. That frame may scale differently than other content.
 */

struct ZoomableScrollView<Content: View>: View {
    
    @ViewBuilder var content: (CustomViewProxy) -> Content
    
    let viewTag = ScrollState.viewTag
    let showDiagnostics = false
    
    @State var zoomLevel: Double = 1.0
    @State var focusedContentFrame: CGRect = .zero
    @State private var contentViewFrame: CGRect = .zero
    @State var scrollRequestSubject = PassthroughSubject<ZoomScrollRequest, Never>()
    @State var _scrollReaderProxy: ScrollViewProxy? = nil
    @State var lastZoomScrollRequest: ZoomScrollRequest? = nil
    var body: some View {
        
        VStack {
            if showDiagnostics {
                VStack (alignment: .leading) {
                    Text("ContentFrame: \(contentViewFrame.xAndWidthDescription)")
                        .font(.footnote)
                    Text("ZoomScrollRequest: \(lastZoomScrollRequest.debugDescription)")
                        .font(.footnote)
                }
                .background {
                    Rectangle()
                        .foregroundColor(.gray)
                }
                .frame(height: 250.0)
                
            }
            GeometryReader { scrollViewGeometry in
                ZStack {
                    if showDiagnostics {
                        HStack (spacing: 0) {
                            Rectangle()
                                .fill(.clear)
                                .border(.green)
                                .frame(width: (scrollViewGeometry.size.width) / 2.0, height: scrollViewGeometry.size.height)
                            Rectangle()
                                .fill(.clear)
                                .border(.green)
                                .frame(width: (scrollViewGeometry.size.width) / 2.0, height: scrollViewGeometry.size.height)
                        }.padding(0)
                    }
                    ScrollViewReader { scrollReaderProxy in
                        ScrollView ([.horizontal]) {
                            content(CustomViewProxy(handleZoomScrollRequest: handleZoomScrollRequest(_:),
                                                    scrollLeading: scrollLeading,
                                                    scrollCenter: scrollCenter,
                                                    scrollTrailing: scrollTrailing
                                                   )
                            )
                            .frame(width: scrollViewGeometry.size.width * zoomLevel)
                            .animation(nil, value: zoomLevel)
                            .animation(nil, value: scrollViewGeometry.size.width)
                            .id(viewTag)
                            .background {
                                GeometryReader { contentViewGeometry in
                                    HStack (spacing: 0) {
                                        Rectangle()
                                            .fill(.clear)
                                            .border(showDiagnostics ? .red : .clear)
                                            .frame(width: (focusedContentFrame.width) / 2.0, height: contentViewGeometry.size.height)
                                        Rectangle()
                                            .fill(.clear)
                                            .border(showDiagnostics ? .blue : .clear)
                                            .frame(width: (focusedContentFrame.width) / 2.0, height: contentViewGeometry.size.height)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .preference(key: ContentViewFrameKey.self, value: contentViewGeometry.frame(in: .named("scrollView")))
                                    .onPreferenceChange(ContentViewFrameKey.self) { value in
                                        self.contentViewFrame = value
                                        //print(value)
                                    }
                                    .onReceive(scrollRequestSubject) { zoomScrollRequest in
                                        zoom(zoomScrollRequest: zoomScrollRequest, scrollReaderProxy: scrollReaderProxy, contentViewSize: contentViewGeometry.size, scrollViewSize: scrollViewGeometry.size)
                                    }
                                    .onAppear {
                                        _scrollReaderProxy = scrollReaderProxy
                                    }
                                }
                            }
                        }.coordinateSpace(name: "scrollView")
                    }
                }
            }
        }
    }
    
    func zoom(zoomScrollRequest: ZoomScrollRequest, scrollReaderProxy: ScrollViewProxy, contentViewSize: CGSize, scrollViewSize: CGSize) {
        self.lastZoomScrollRequest = zoomScrollRequest
        let viewState = ScrollState(focusedContentFrame: focusedContentFrame, scrollRect: self.contentViewFrame, scrollViewSize: scrollViewSize, contentViewSize: contentViewSize)
        
        switch zoomScrollRequest.scrollType {
        case .scrollViewCenter:
            if viewState.isScrolledToLeadingSide() {
                scrollToLeadingEdgeAndZoom(zoomLevel: zoomScrollRequest.zoomAmount, scrollReaderProxy: scrollReaderProxy)
                self.focusedContentFrame = zoomScrollRequest.updatedFocusedContentFrame
            } else if viewState.isScrolledToTrailingSide() {
                self.focusedContentFrame = zoomScrollRequest.updatedFocusedContentFrame
                scrollToTrailingEdgeAndZoom(zoomLevel: zoomScrollRequest.zoomAmount, scrollReaderProxy: scrollReaderProxy)
            } else {
                zoom(zoomLevel: zoomScrollRequest.zoomAmount, updatedFocusedContentFrame: zoomScrollRequest.updatedFocusedContentFrame, focusContentAnchor: viewState.focusedContentFrameCenterAnchor(), scrollViewAnchor: 0.5, viewState: viewState, scrollReaderProxy: scrollReaderProxy)
            }
        case .contentPoint(let location):
            let focusContentAnchor = viewState.getFocusContentAnchor(contentViewX: location.x)
            let scrollViewAnchor = viewState.getScrollViewAnchor(contentViewX: location.x)
            zoom(zoomLevel: zoomScrollRequest.zoomAmount, updatedFocusedContentFrame: zoomScrollRequest.updatedFocusedContentFrame, focusContentAnchor: focusContentAnchor, scrollViewAnchor: scrollViewAnchor, viewState: viewState, scrollReaderProxy: scrollReaderProxy)
        }
    }
    
    func zoom(zoomLevel: Double, updatedFocusedContentFrame: CGRect, focusContentAnchor: Double, scrollViewAnchor: Double, viewState: ScrollState, scrollReaderProxy: ScrollViewProxy) {
        withAnimation(.none) {
            let upcomingViewState = viewState.transforming(zoomLevel: zoomLevel, updatedFocusedContentFrame: updatedFocusedContentFrame, anchor: focusContentAnchor, scrollViewAnchor: scrollViewAnchor)
            upcomingViewState.scrollToAnchor(focusContentAnchor: focusContentAnchor, scrollViewAnchor: scrollViewAnchor, scrollReaderProxy: scrollReaderProxy)
            self.zoomLevel = zoomLevel
            self.focusedContentFrame = updatedFocusedContentFrame
        }
    }
    
    func handleZoomScrollRequest(_ request: ZoomScrollRequest) {
        if zoomLevel == request.zoomAmount {
            return
        }
        scrollRequestSubject.send(request)
    }

    //MARK: Convenience scroll methods
    
    func scrollLeading() {
        guard let scrollReaderProxy = _scrollReaderProxy else {return}
        scrollToLeadingEdgeAndZoom(zoomLevel: zoomLevel, scrollReaderProxy: scrollReaderProxy)
    }
    
    func scrollToLeadingEdgeAndZoom(zoomLevel: Double, scrollReaderProxy: ScrollViewProxy) {
        scrollReaderProxy.scrollTo(viewTag, anchor: .leading)
        self.zoomLevel = zoomLevel
    }
    
    func scrollCenter() {
        guard let scrollReaderProxy = _scrollReaderProxy else {return}
        scrollCenter(scrollReaderProxy: scrollReaderProxy)
    }
    
    func scrollCenter(scrollReaderProxy: ScrollViewProxy) {
        scrollReaderProxy.scrollTo(ScrollState.viewTag, anchor: .init(x: 0.5, y: 0.5))
    }
    
    func scrollTrailing() {
        guard let scrollReaderProxy = _scrollReaderProxy else {return}
        scrollToTrailingEdgeAndZoom(zoomLevel: zoomLevel, scrollReaderProxy: scrollReaderProxy)
    }
    
    func scrollToTrailingEdgeAndZoom(zoomLevel: Double, scrollReaderProxy: ScrollViewProxy) {
        scrollReaderProxy.scrollTo(viewTag, anchor: .trailing)
        self.zoomLevel = zoomLevel
    }
}

struct ZoomScrollRequest: Equatable, CustomStringConvertible {
    
    let date = Date()
    let scrollType: ScrollType
    let updatedFocusedContentFrame: CGRect
    let zoomAmount: Double
    
    var description: String {
        return """
        scrollType: \(scrollType)
        focusedContentFrame: \(updatedFocusedContentFrame.xAndWidthDescription)
        zoomAmount: \(zoomAmount)
        """
    }
}

enum ScrollType: Equatable {
    case scrollViewCenter
    case contentPoint(CGPoint)
}

struct ContentViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    }
}

struct ScrollState {
    
    let focusedContentFrame: CGRect
    let scrollRect: CGRect
    let scrollViewSize: CGSize
    let contentViewSize: CGSize
    static let viewTag = 100
    
    
    //MARK: Edge Checks
    
    func isScrolledToViewSides() -> Bool {
        return isScrolledToLeadingSide() || isScrolledToTrailingSide()
    }
    
    func isScrolledToLeadingSide() -> Bool {
        let leadingScrollViewX = abs(scrollRect.origin.x)
        return abs(leadingScrollViewX) < 2.0
    }
    
    func isScrolledToTrailingSide() -> Bool {
        let trailingScrollViewX = abs(scrollRect.origin.x) + scrollViewSize.width
        return abs(trailingScrollViewX - contentViewSize.width) < 2.0
    }
    
    //MARK: Focused Content Frame
    func focusedContentFrameCenterAnchor() -> Double {
        let xPosition = abs(scrollRect.origin.x) + (scrollViewSize.width / 2.0)
        return xPosition / focusedContentFrame.width
    }
    
    func getFocusContentAnchor(contentViewX: Double) -> Double {
        return (contentViewX) / focusedContentFrame.width
    }
    
    func getScrollViewAnchor(contentViewX: Double) -> Double {
        let xPositionInScrollView = contentViewX - abs(scrollRect.origin.x)
        return xPositionInScrollView / scrollViewSize.width
    }
    
    func getScrollViewRect(focusContentAnchor: Double, scrollViewAnchor: Double) -> CGRect {
        
        var xPosition = focusedContentFrame.width * focusContentAnchor
        
        //Add position in the scrollViewAnchor
        //TODO: This should have a 0 origin and instead adjust the contentView rect.
        //Note though that self.scrollRect has a non-zero origin, so maybe his is ok?
        xPosition = xPosition - (scrollViewSize.width * scrollViewAnchor)
        return CGRect(origin: CGPoint(x: xPosition, y: 0.0),
                      size: CGSize(width: scrollViewSize.width, height: 100.0))
        
    }
    
    func scrollToAnchor(focusContentAnchor: Double, scrollViewAnchor: Double, scrollReaderProxy: ScrollViewProxy) {
        //TODO: This may be working backwards. The contentViewRect is what should be offset (negative)
        let scrollViewRect = getScrollViewRect(focusContentAnchor: focusContentAnchor, scrollViewAnchor: scrollViewAnchor)
        let contentViewRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0),
                                   size: CGSize(width: contentViewSize.width, height: 100.0))
        
        if scrollViewRect.minX < 0 {
            scrollReaderProxy.scrollTo(Self.viewTag, anchor: .leading)
        }
        if scrollViewRect.maxX > contentViewRect.size.width {
            scrollReaderProxy.scrollTo(Self.viewTag, anchor: .trailing)
        } else {
            let sharedUnitPoint = calculateSharedUnitPoint(rectA: scrollViewRect, rectB: contentViewRect)
            scrollReaderProxy.scrollTo(Self.viewTag, anchor: .init(x: sharedUnitPoint, y: 0))
        }
    }
    
    func calculateSharedUnitPoint(rectA: CGRect, rectB: CGRect) -> Double {
        let ax1 = rectA.origin.x
        let ax2 = rectA.origin.x + rectA.size.width
        let bx1 = rectB.origin.x
        let bx2 = rectB.origin.x + rectB.size.width
        let numerator = bx1 - ax1
        let denominator = ax2 - ax1 - bx2 + bx1
        return numerator / denominator
    }
    
    func transforming(zoomLevel: Double, updatedFocusedContentFrame: CGRect, anchor: Double, scrollViewAnchor: Double?) -> ScrollState {
        
        let updatedContentViewSize = CGSize(width: scrollViewSize.width * zoomLevel, height: scrollViewSize.height * zoomLevel)

        var anchorXPosition = updatedContentViewSize.width * anchor
        if let scrollViewAnchor {
            let scrollViewXOffset = scrollViewSize.width * scrollViewAnchor
            anchorXPosition = anchorXPosition - scrollViewXOffset
        }

        let updatedScrollRect = CGRect(x: anchorXPosition, y: 0.0, width: scrollViewSize.width, height: scrollRect.height)

        return ScrollState(focusedContentFrame: updatedFocusedContentFrame, scrollRect: updatedScrollRect, scrollViewSize: scrollViewSize, contentViewSize: updatedContentViewSize)
    }
}


struct CustomViewProxy {
    let handleZoomScrollRequest: (_ request: ZoomScrollRequest) -> Void
    let scrollLeading: () -> Void
    let scrollCenter: () -> Void
    let scrollTrailing: () -> Void
}

extension CGRect {
    var xAndWidthDescription: String {
        return "x: \(formatValue(self.origin.x)), w: \(formatValue(self.size.width))"
    }

    private func formatValue(_ value: CGFloat) -> String {
        return (value.truncatingRemainder(dividingBy: 1) == 0) ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }
}
