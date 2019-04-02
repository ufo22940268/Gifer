//
//  TextRender.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class TextRender: UILabel, OverlayComponentRenderable {
    
    override var bounds: CGRect {
        didSet {
            updateFontSize()
        }
    }
    
    var info: EditTextInfo!
    
    init(info: EditTextInfo) {
        super.init(frame: .zero)
        self.info = info
        useAutoLayout()
        adjustsFontSizeToFitWidth = true
        font = UIFont(name: info.fontName, size: 50)
        textColor = info.textColor
        text = info.text
        textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func copy() -> OverlayComponentRender {
        return TextRender(info: self.info)
    }
    
    private func updateFontSize() {
        
    }
}
