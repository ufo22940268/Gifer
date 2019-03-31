//
//  Overlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class Overlay: UIView {
    
    var components = [OverlayComponent]()
    
    func addComponent(component: OverlayComponent) {
        components.append(component)
        addSubview(component)
        component.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        components.forEach { $0.updateInfoPosition() }
    }
}
