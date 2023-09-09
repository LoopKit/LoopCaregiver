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
    @Environment(\.colorScheme) var colorScheme
    
    @ViewBuilder var body: some View {
        VStack {
            ZStack {
                HalfFilledAnnotationView(fillColorStyle: graphItem.annotationFillColor(), fillStyle: graphItem.annotationFillStyle())
                    .frame(width: graphItem.annotationWidth(), height: graphItem.annotationHeight())
                if graphItem.shouldShowLabel() {
                    Text(graphItem.formattedValue())
                        .frame(width: 30.0)
                        .font(.system(size: graphItem.fontSize()))
                        .font(.footnote)
                        .foregroundColor(fontColor)
                        .strikethrough(isError, pattern: .solid, color: .red)
                        .offset(.init(width: 0.0, height: fontOffsetFromAnnotationCenter(labelPosition: graphItem.annotationLabelPosition())))
                }
            }
        }
    }
    
    var fontColor: Color {
        switch graphItem.graphItemState {
        case .error:
            return Color.red
        case .pending:
            return Color.yellow
        default:
            if colorScheme == .dark {
                return .white
            } else {
                return .black
            }
        }
    }
    
    var isError: Bool {
        switch graphItem.graphItemState {
        case .error:
            return true
        default:
            return false
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
        let fillColorStyle: AnnotationColorStyle
        let fillStyle: FillStyle
        @Environment(\.colorScheme) var colorScheme
        
        @ViewBuilder var body: some View {
            switch fillStyle {
            case .noFill:
                Circle()
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            case .bottomFill:
                Circle()
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
                    .background(Circle().trim(from: 0.0, to: 0.5).fill(fillColorStyle.color(scheme: colorScheme)))
            case .topFill:
                Circle()
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
                    .background(Circle().trim(from: 0.5, to: 1.0).fill(fillColorStyle.color(scheme: colorScheme)))
            case .fullFill:
                Circle()
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            }
        }
        
        var strokeWidth: CGFloat {
            return 0.5
        }
        
        var strokeColor: Color {
            return .gray
        }
        
        enum FillStyle {
            case noFill
            case topFill
            case bottomFill
            case fullFill
        }
    }
}
