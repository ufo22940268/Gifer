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
    
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                components.forEach { $0.isActive = false }
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapOtherSpace(sender:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deactiveComponents() {
        components.forEach { $0.isActive = false }
    }
    
    @objc func onTapOtherSpace(sender: UITapGestureRecognizer) {
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
        component.isActive = true
        components.filter { $0 != component }.forEach { $0.isActive = false }
        delegate?.onActive(overlay: self, component: component)
    }
    
    func getComponent(on componentId: ComponentId) -> OverlayComponent {
        return components.first { $0.id == componentId }!
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isEnabled {
            return nil
        }
        
        if components.contains(where: { $0.point(inside: $0.convert(point, from: self), with: event) }) {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
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
