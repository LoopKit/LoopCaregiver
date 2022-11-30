//
//  PinchZoom.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/27/22.
//

import SwiftUI
import UIKit

class PinchZoomView: UIView {
    let minScale: CGFloat
    let maxScale: CGFloat
    var isPinching: Bool = false
    var scale: CGFloat = 1.0 {
        didSet {
            scaleChange(scale)
        }
    }
    var previousScale: CGFloat = 0.0
    let scaleChange: (CGFloat) -> Void
    
    init(minScale: CGFloat,
           maxScale: CGFloat,
         currentScale: CGFloat,
         scaleChange: @escaping (CGFloat) -> Void) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.scale = currentScale
        self.scaleChange = scaleChange
        super.init(frame: .zero)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        pinchGesture.cancelsTouchesInView = false
        addGestureRecognizer(pinchGesture)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gesture:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            
        case .changed, .ended:
            
            var updatedScale = gesture.scale
            if previousScale != 0 {
                updatedScale = previousScale * gesture.scale
            }

            if updatedScale <= minScale {
                updatedScale = minScale
            } else if gesture.scale >= maxScale {
                updatedScale = maxScale
            }
            
            if gesture.state == .ended {
                isPinching = false
                updateScale(updatedScale: updatedScale, scrollState: .final)
            } else {
                updateScale(updatedScale: updatedScale, scrollState: .inProgress)
            }
            
        case .cancelled, .failed:
            updateScale(updatedScale: 1.0, scrollState: .final)
        default:
            break
        }
    }
    
    @objc private func doubleTap(gesture: UIPinchGestureRecognizer) {
        var updatedScale = 0.0
        if scale > 1.0 {
            updatedScale = 1.0
        } else if scale < 1.0 {
            updatedScale = 1.0
        } else { //1.0
            updatedScale = 2.0
        }
        updateScale(updatedScale: updatedScale, scrollState: .final)
    }
    
    func updateScale(updatedScale: Double, scrollState: ScrollState) {
        if scrollState == .final {
            previousScale = updatedScale
        }

        scale = updatedScale
    }
    
    enum ScrollState {
        case inProgress
        case final
    }
    
}

struct PinchZoom: UIViewRepresentable {
    let minScale: CGFloat
    let maxScale: CGFloat
    @Binding var scale: CGFloat
    @Binding var isPinching: Bool
    
    func makeUIView(context: Context) -> PinchZoomView {
        let pinchZoomView = PinchZoomView(minScale: minScale, maxScale: maxScale, currentScale: scale, scaleChange: { scale = $0 })
        return pinchZoomView
    }
    
    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }
}

struct PinchToZoom: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    @Binding var scale: CGFloat
    @State var anchor: UnitPoint = .center
    @State var isPinching: Bool = false
    
    func body(content: Content) -> some View {
        content
//            .scaleEffect(scale, anchor: anchor)
            .animation(.spring(), value: isPinching)
            .overlay(PinchZoom(minScale: minScale, maxScale: maxScale, scale: $scale, isPinching: $isPinching))
    }
}
