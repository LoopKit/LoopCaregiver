//
//  CGRect.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 8/18/23.
//

import Foundation

extension CGRect {
    func scaledBy(_ scale: CGFloat) -> CGRect {
        let widthDifference = self.width * (1.0 - scale) / 2.0
        let heightDifference = self.height * (1.0 - scale) / 2.0

        return CGRect(
            x: self.origin.x + widthDifference,
            y: self.origin.y + heightDifference,
            width: self.width * scale,
            height: self.height * scale
        )
    }
}
