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
        component.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        components.forEach { $0.updateInfoPosition() }
    }
    
    private func active(component: OverlayComponent) {
        component.isActive = true
        components.filter { $0 != component }.map { $0.isActive = false }
    }
}

extension Overlay: OverlayComponentDelegate {
    func onCopyComponent(component: OverlayComponent) {
        let newComponent = component.copyView()
        addComponent(component: newComponent)
        active(component: newComponent)
    }
    
    func onComponentDeleted(component: OverlayComponent) {
        components.removeAll { $0 == component }
        component.removeFromSuperview()
    }
}