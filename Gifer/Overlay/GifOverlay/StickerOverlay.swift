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
    
    func addStickerComponent(_ sticker: StickerInfo) {
        let stickerRender = StickerRender(info: sticker).useAutoLayout()
        let componentInfo = OverlayComponent.Info(stickerInfo:sticker, containerBounds: self.bounds)
        let component: OverlayComponent = OverlayComponent(info: componentInfo, render: stickerRender)
        addComponent(component: component)        
        active(component: component)
    }
}
