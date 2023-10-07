//
//  OverrideInsulinNeedsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/6/23.
//

import SwiftUI

struct OverrideInsulinNeedsView: View {
    
    var ratioComplete = 0.0
    
    private let heightToWidthRatio = 0.1
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                //Long one
                fillableCapsule(fillRatio: longFillRatio, fillColor: Color.orange)
                //Short one
                HStack {
                    fillableCapsule(fillRatio: shortFillRatio, fillColor: Color.orange)
                        .frame(width: proxy.size.width * 0.5)
                    Spacer(minLength: 0.0)
                }
            }
        }
        
        var longFillRatio: Double {
            min(1.0, ratioComplete * 0.5)
        }
        
        var shortFillRatio: Double {
            min(1.0, ratioComplete)
        }
    }
    
    func fillableCapsule(fillRatio: Double, fillColor: Color) -> some View {
        
        GeometryReader { proxy in
            ZStack {
                Capsule()
                    .fill(Color.white)
                Capsule()
                    .stroke(Color.gray, lineWidth: lineWidth(viewHeight: proxy.size.height))
                HStack {
                    Capsule()
                        .fill(fillColor)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, lineWidth(viewHeight: proxy.size.height))
                        .frame(width: proxy.size.width * fillRatio, height: proxy.size.height)
                    Spacer(minLength: 0.0)

                }
                
            }
        }
        
    }
    
    func lineWidth(viewHeight: Double) -> Double {
        return viewHeight > 10.0 ? 2.0 : 1.0
    }
}

struct OverrideInsulinNeedsView_Previews: PreviewProvider {
    static var previews: some View {
        OverrideInsulinNeedsView(ratioComplete: 1.2)
            .frame(width: 200.0, height: 20.0)
    }
}
