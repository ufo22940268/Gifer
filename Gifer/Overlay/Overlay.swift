//
//  Overlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OverlayDelegate: class {
    func onEdit(component: OverlayComponent, id: ComponentId)
    func onActive(overlay: Overlay, component: OverlayComponent)
}

class Overlay: UIView {
    var components = [OverlayComponent]()
    
    weak var delegate: OverlayDelegate?
    var componentIdSequence: ComponentId = 0
    var clipTrimPosition: VideoTrimPosition!
    
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                components.forEach { $0.isActive = false }
            }
            
            pinchRecognizer.isEnabled = isEnabled
        }
    }
    
    var pinchRecognizer: UIPinchGestureRecognizer!
    
    override func awakeFromNib() {
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(sender:)))
        addGestureRecognizer(pinchRecognizer)
        pinchRecognizer.isEnabled = false
    }
    
    var activeComponent: OverlayComponent? {
        return components.first { $0.isActive }
    }
    
    var startScale: CGFloat = 1.0
    
    @objc func onPinch(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            startScale = sender.scale
        case .changed:
            activeComponent?.scaleBy(sender.scale/startScale, anchorCenter: true)
            startScale = sender.scale
        default:
            break
        }
    }
            
    func deactiveComponents() {
        pinchRecognizer.isEnabled = false
        components.forEach { $0.isActive = false }
    }
    
    func addComponent(component: OverlayComponent) {
        components.append(component)
        addSubview(component)
        component.setup(id: componentIdSequence)
        component.delegate = self
        
        componentIdSequence += 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        components.forEach { $0.updateInfoPosition() }
    }
    
    func active(component: OverlayComponent) {
        pinchRecognizer.isEnabled = true
        component.isActive = true
        components.filter { $0 != component }.forEach { $0.isActive = false }
        delegate?.onActive(overlay: self, component: component)
    }
    
    func getComponent(on componentId: ComponentId) -> OverlayComponent {
        return components.first { $0.id == componentId }!
    }
}

extension Overlay: OverlayComponentDelegate {
    func onActive(component: OverlayComponent) {
        active(component: component)
    }
    
    func onCopyComponent(component: OverlayComponent) {
        let newComponent = component.copyView()
        addComponent(component: newComponent)
        active(component: newComponent)
    }
    
    func onComponentDeleted(component: OverlayComponent) {
        components.removeAll { $0 == component }
        component.removeFromSuperview()
    }
    
    func onEditComponent(component: OverlayComponent, id: ComponentId) {
        delegate?.onEdit(component: component, id: id)
    }
}
