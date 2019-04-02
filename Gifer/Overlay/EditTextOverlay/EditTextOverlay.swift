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
        let info = OverlayComponent.Info(nRect: CGRect(origin: CGPoint(x: 0.2, y: 0.2), size: CGSize(width: 0.3, height: 0.3)))
        let textRender = TextRender(info: textInfo).useAutoLayout()
        let component: OverlayComponent = OverlayComponent(info: info, renderer: textRender)
        addComponent(component: component)
        active(component: component)
    }
}
