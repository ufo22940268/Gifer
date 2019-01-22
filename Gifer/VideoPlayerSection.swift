//
//  VideoPlayerSection.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class VideoPlayerSection: UIView {

    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let cropContainer = subviews.filter({ (view) -> Bool in
            view is CropContainer
        }).first!
        return cropContainer.hitTest(self.convert(point, to: cropContainer), with: event)
    }
}
