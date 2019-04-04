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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func predictComponentNormalizedRect(textInfo: EditTextInfo) -> CGRect {
        let text = textInfo.text
        let preferredTextSize = CGFloat(18)
        let preferredSize = CGSize(width: preferredTextSize*CGFloat(text.count), height: preferredTextSize*1.5)
        let preferredRect = CGRect(origin: CGPoint(x: bounds.midX, y: bounds.midY).applying(CGAffineTransform(translationX: -preferredSize.width/2, y: -preferredSize.height/2)), size: preferredSize).insetBy(dx: -44, dy: -44)
        
        let boundsRect = bounds.inset(by: UIEdgeInsets(top: 62, left: 62, bottom: 62, right: 62))
        return preferredRect.intersection(boundsRect).applying(CGAffineTransform(scaleX: 1/bounds.width, y: 1/bounds.height))
    }
    
    func addTextComponent(textInfo: EditTextInfo) {
        let info = OverlayComponent.Info(nRect: predictComponentNormalizedRect(textInfo: textInfo))
        let textRender = TextRender(info: textInfo).useAutoLayout()
        let component: OverlayComponent = OverlayComponent(info: info, render: textRender)
        addComponent(component: component)
        active(component: component)
    }
    
    func updateTextComponent(textInfo: EditTextInfo, componentId: ComponentId) {
        let component = getComponent(on: componentId)
        let textRender = component.render as! TextRender
        textRender.info = textInfo
    }
}
