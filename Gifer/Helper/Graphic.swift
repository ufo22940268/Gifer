//
//  Graphic.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/31.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    func scaleOnCenterPoint(scaleX: CGFloat, scaleY: CGFloat) -> CGRect {
        let origin = self
        return self.applying(CGAffineTransform(translationX: -midX, y: -midY))
            .applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
            .applying(CGAffineTransform(translationX: origin.midX, y: origin.midY))
    }
}

extension UIColor {
    static let main: UIColor = UIColor(named: "mainColor")!
}
