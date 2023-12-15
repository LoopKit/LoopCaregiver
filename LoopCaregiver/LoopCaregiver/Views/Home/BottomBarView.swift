//
//  BottomBarView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import Foundation
import LoopCaregiverKit
import SwiftUI

struct BottomBarView: View {

    @Binding var showCarbView: Bool
    @Binding var showBolusView: Bool
    @Binding var showOverrideView: Bool
    @Binding var showSettingsView: Bool
    @ObservedObject var remoteDataSource: RemoteDataServiceManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack (alignment: .center) {
            Button {
                showCarbView = true
            } label: {
                Image("carbs")
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
        .background(barBackgroundColor)
        .frame(height: 40, alignment: .center)
    }
    
    func iconSize() -> Double {
        return 40.0
    }
    
    func overrideIsActive() -> Bool {
        remoteDataSource.activeOverride() != nil
    }
    
    var barBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        } else {
            return Color(red: 0.97, green: 0.97, blue: 0.97)
        }
    }
}
