//
//  EditTextOverlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class EditTextOverlay: Overlay {

    var allRenders: [TextRender] {
        return components.map { $0.render as! TextRender }
    }
        
    func getTextInfosForExport(imageView: UIView) -> [EditTextInfo] {
        return components.map { component in
            let render = component.render as! TextRender
            var textInfo = render.info!
            textInfo.nRect = render.convert(render.bounds, to: imageView)
                .normalizeRect(containerSize: imageView.bounds.size)
            textInfo.fontSize = render.fontSize
            textInfo.rotation = component.rotation
            textInfo.trimPosition = component.trimPosition
            return textInfo
        }
    }
    
    @discardableResult
    func addTextComponent(textInfo: EditTextInfo) -> OverlayComponent {
        let info = OverlayComponent.Info(nRect: OverlayComponent.Info.predictNormalizedRect(textInfo: textInfo, containerBounds: self.bounds))
        let textRender = TextRender(info: textInfo).useAutoLayout()
        let component: OverlayComponent = OverlayComponent(info: info, render: textRender, clipTrimPosition: clipTrimPosition)
        addComponent(component: component)
        active(component: component)
        return component
    }
    
    func updateTextComponent(textInfo: EditTextInfo, componentId: ComponentId) {
        let componentSize = OverlayComponent.Info.predictNormalizedSize(textInfo: textInfo, containerBounds: self.bounds)
        let component = getComponent(on: componentId)
        component.change(nSize: componentSize)
        let textRender = component.render as! TextRender
        textRender.info = textInfo
        component.width.constant = componentSize.width
        component.height.constant = componentSize.height
    }
}
