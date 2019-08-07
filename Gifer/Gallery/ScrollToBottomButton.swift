//
//  ScrollToBottomButton.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ScrollToBottomButton: UIButton {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -8, dy: -8).contains(point)
    }
}
