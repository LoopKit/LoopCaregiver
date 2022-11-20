//
//  TreatmentAnnotationView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import Foundation
import SwiftUI

struct TreatmentAnnotationView: View {
    @State var graphItem: GraphItem
    
    @ViewBuilder var body: some View {
        VStack {
            ZStack {
                HalfFilledAnnotationView(color: graphItem.annotationFillColor(), fillStyle: graphItem.annotationFillStyle())
                    .frame(width: graphItem.annotationWidth(), height: graphItem.annotationHeight())
                if graphItem.shouldShowLabel() {
                    Text(graphItem.formattedValue())
                        .frame(width: 30.0)
                        .font(.system(size: graphItem.fontSize()))
                        .font(.footnote)
                        .offset(.init(width: 0.0, height: fontOffsetFromAnnotationCenter(labelPosition: graphItem.annotationLabelPosition())))
                }
            }
        }
    }
    
    func fontHeight() -> CGFloat {
        return 20.0
    }
    
    func fontOffsetFromAnnotationCenter(labelPosition: GraphItem.GraphItemLabelPosition) -> CGFloat {
        let offset = -graphItem.annotationWidth() / 2.0 - fontHeight() / 2.0
        if labelPosition == .top {
            return offset
        } else {
            return -offset
        }
    }
    
    struct HalfFilledAnnotationView: View {
        
        let color: Color
        let fillStyle: FillStyle
        @Environment(\.colorScheme) var colorScheme
        
        @ViewBuilder var body: some View {
            switch fillStyle {
            case .bottomFill:
                Circle()
                    .stroke()
                    .foregroundColor(.white)
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .fill(.blue)
            case .topFill:
                Circle()
                    .stroke()
                    .foregroundColor(.blue)
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .fill(colorScheme == .dark ? Color.white : Color.brown)
            case .fullFill:
                Circle()
            }
        }
        
        enum FillStyle {
            case topFill
            case bottomFill
            case fullFill
        }
    }
}
