//
//  EditTextOverlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class EditTextOverlay: Overlay {

    init() {
        super.init(frame: .zero)
        let info = OverlayComponent.Info(nRect: CGRect(origin: CGPoint(x: 0.2, y: 0.2), size: CGSize(width: 0.3, height: 0.3)))
        addComponent(component: OverlayComponent(info: info))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
