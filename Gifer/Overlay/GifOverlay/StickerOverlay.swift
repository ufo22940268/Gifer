//
//  StickerOverlay.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class StickerOverlay: Overlay {
    
    var stickerInfos: [StickerInfo] {
        return components.map { component in
            let stickerRender = component.render as! StickerRender
            var info = stickerRender.info!
            let stickerFrame = stickerRender.convert(stickerRender.bounds, to: self)
            info.imageFrame = stickerFrame
                .aspectFit(in: stickerFrame, ratio: info.image.size)
                .normalizeRect(containerSize: bounds.size)
            info.rotation = component.rotation
            info.trimPosition = component.trimPosition
            return info
        }
    }
    
    func addStickerComponent(_ sticker: StickerInfo) -> OverlayComponent {
        let stickerRender = StickerRender(info: sticker).useAutoLayout()
        let componentInfo = OverlayComponent.Info(stickerInfo:sticker, containerBounds: self.bounds)
        let component: OverlayComponent = OverlayComponent(info: componentInfo, render: stickerRender, clipTrimPosition: clipTrimPosition)
        addComponent(component: component)
        active(component: component)
        return component
    }
    
    func update(sticker: StickerInfo, for component: OverlayComponent) {
        let render = component.render as! StickerRender
        render.image = sticker.image
    }
}
