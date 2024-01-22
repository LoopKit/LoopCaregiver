//
//  View.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/27/22.
//

import SwiftUI

public extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
