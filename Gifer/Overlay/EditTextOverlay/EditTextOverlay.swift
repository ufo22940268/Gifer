//
//  EditTextOverlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class EditTextOverlay: Overlay {

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var allRenders: [TextRender] {
        return components.map { $0.render as! TextRender }
    }
    
    var textInfos: [EditTextInfo] {
        return allRenders.map { render in
            var textInfo = render.info!
            textInfo.nRect = render.convert(render.frame, to: self)
                .normalizeRect(containerSize: bounds.size)
            textInfo.fontSize = render.font.pointSize
            return textInfo
        }
    }
    
    func addTextComponent(textInfo: EditTextInfo) {
        let info = OverlayComponent.Info(nRect: OverlayComponent.Info.predictNormalizedRect(textInfo: textInfo, containerBounds: self.bounds))
        let textRender = TextRender(info: textInfo).useAutoLayout()
        let component: OverlayComponent = OverlayComponent(info: info, render: textRender)
        addComponent(component: component)
        active(component: component)
        textRender.updateFontSize()
    }
    
    func updateTextComponent(textInfo: EditTextInfo, componentId: ComponentId) {
        let componentSize = OverlayComponent.Info.predictNormalizedSize(textInfo: textInfo, containerBounds: self.bounds)
        let component = getComponent(on: componentId)
        component.change(nSize: componentSize)
        let textRender = component.render as! TextRender
        textRender.info = textInfo
    }
}
