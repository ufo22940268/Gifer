//
//  StickerRender.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class StickerRender: UIImageView, OverlayComponentRenderable {
    var info: StickerInfo!
    
    init(info: StickerInfo) {
        super.init(frame: .zero)
        self.info = info
        self.image = info.image
        contentMode = .scaleAspectFit
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func copy() -> OverlayComponentRender {
        return self
    }    
}
