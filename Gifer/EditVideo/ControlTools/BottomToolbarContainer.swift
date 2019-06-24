//
//  BottomToolbarContainer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class BottomToolbarContainer: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawTopSeparator(rect: rect)
    }

}
