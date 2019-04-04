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
    
    
    func addTextComponent(textInfo: EditTextInfo) {
        let info = OverlayComponent.Info(nRect: OverlayComponent.Info.predictNormalizedRect(textInfo: textInfo, containerBounds: self.bounds))
        let textRender = TextRender(info: textInfo).useAutoLayout()
        let component: OverlayComponent = OverlayComponent(info: info, render: textRender)
        addComponent(component: component)
        active(component: component)
    }
    
    func updateTextComponent(textInfo: EditTextInfo, componentId: ComponentId) {
        let componentSize = OverlayComponent.Info.predictNormalizedSize(textInfo: textInfo, containerBounds: self.bounds)
        let component = getComponent(on: componentId)
        component.change(nSize: componentSize)
        let textRender = component.render as! TextRender
        textRender.info = textInfo
    }
}
