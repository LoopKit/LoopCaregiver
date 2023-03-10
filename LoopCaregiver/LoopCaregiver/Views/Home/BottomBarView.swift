//
//  BottomBarView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import Foundation

import SwiftUI

struct BottomBarView: View {

    @Binding var showCarbView: Bool
    @Binding var showBolusView: Bool
    @Binding var showOverrideView: Bool
    @Binding var showSettingsView: Bool
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    
    var body: some View {
        HStack (alignment: .center) {
            Button {
                showCarbView = true
            } label: {
                Image("Pre-Meal")
                    .renderingMode(.template)
                    .foregroundColor(.green)
                    .frame(width: iconSize(), height: iconSize())
                    .padding(.leading)
            }
            Spacer()
            Button {
                showBolusView = true
            } label: {
                Image("bolus")
                    .renderingMode(.template)
                    .foregroundColor(.orange)
                    .frame(width: iconSize(), height: iconSize())
            }
            Spacer()
            Button {
                showOverrideView = true
            } label: {
                Image(overrideIsActive() ? "workout-selected" : "workout")
                    .renderingMode(.template)
                    .foregroundColor(.blue)
                    .frame(width: iconSize(), height: iconSize())
            }
            Spacer()
            Button {
                showSettingsView = true
            } label: {
                Image("settings")
                    .renderingMode(.template)
                    .foregroundColor(.gray)
                    .frame(width: iconSize(), height: iconSize())
                    .padding(.trailing)
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .frame(height: 40, alignment: .center)
    }
    
    func iconSize() -> Double {
        return 40.0
    }
    
    func overrideIsActive() -> Bool {
        remoteDataSource.activeOverride() != nil
    }
}
