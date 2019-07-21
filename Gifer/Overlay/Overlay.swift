//
//  Overlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OverlayDelegate: class {
    func onEditComponentTapped(component: OverlayComponent, id: ComponentId)
    func onActiveComponentTapped(overlay: Overlay, component: OverlayComponent)
}

class Overlay: UIView {
    var components = [OverlayComponent]()
    
    weak var delegate: OverlayDelegate?
    var componentIdSequence: ComponentId = 0
    var clipTrimPosition: VideoTrimPosition!
    var pinchRecognizer: UIPinchGestureRecognizer!
    var rotateRecognizer: UIRotationGestureRecognizer!

    override func awakeFromNib() {
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(sender:)))
        addGestureRecognizer(pinchRecognizer)
        pinchRecognizer.isEnabled = false
        pinchRecognizer.delegate = self
        
        rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(onRotate(sender:)))
        addGestureRecognizer(rotateRecognizer)
        rotateRecognizer.isEnabled = false
        rotateRecognizer.delegate = self
    }
    
    var activeComponent: OverlayComponent? {
        return components.first { $0.isActive }
    }
    
    func getHitComponent(point: CGPoint) -> OverlayComponent? {
        return components.first { $0.frame.contains(point) }
    }
    
    var previousScale: CGFloat = 1.0
    
    @objc func onPinch(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            previousScale = sender.scale
        case .changed:
            activeComponent?.scaleBy(sender.scale/previousScale, anchorCenter: true)
            previousScale = sender.scale
        default:
            break
        }
    }
    
    var previousRotation: CGFloat = 0
    @objc func onRotate(sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .began:
            previousRotation = sender.rotation
        case .changed:
            activeComponent?.rotateBy(sender.rotation - previousRotation)
            previousRotation = sender.rotation
        default:
            break
        }
    }
            
    func deactiveComponents() {
        pinchRecognizer.isEnabled = false
        rotateRecognizer.isEnabled = false
        components.forEach { $0.isActive = false }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return components.contains { (component) -> Bool in
            return component.point(inside: convert(point, to: component), with: event)
        }
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
        rotateRecognizer.isEnabled = true
        component.isActive = true
        components.filter { $0 != component }.forEach { $0.isActive = false }
        delegate?.onActiveComponentTapped(overlay: self, component: component)
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
        delegate?.onEditComponentTapped(component: component, id: id)
    }
}

extension Overlay: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if otherGestureRecognizer.view is Overlay {
//            return true
//        } else {
//            return false
//        }
        return false
    }
}
