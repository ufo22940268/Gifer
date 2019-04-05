//
//  TextRender.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

typealias ComponentRender = UIView & OverlayComponentRenderable

class TextRender: UILabel, OverlayComponentRenderable {
    
    override var bounds: CGRect {
        didSet {
            updateFontSize()
        }
    }
    
    var info: EditTextInfo! {
        didSet {
            text = info.text
            font = UIFont(name: info.fontName, size: 50)
            textColor = info.textColor
            sizeToFit()
        }
    }
    
    init(info: EditTextInfo) {
        super.init(frame: .zero)
        defer {
            self.info = info
        }
        baselineAdjustment = .alignCenters
        useAutoLayout()
        adjustsFontSizeToFitWidth = true
        textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func copy() -> OverlayComponentRender {
        return TextRender(info: self.info)
    }
    
    func updateFontSize() {
        font = UIFont(name: font.fontName, size: approximateAdjustedFontSizeWithLabel(self))
    }
}

func approximateAdjustedFontSizeWithLabel(_ label: UILabel) -> CGFloat {
    var currentFont: UIFont = label.font
    let originalFontSize = currentFont.pointSize
    var currentSize: CGSize = (label.text! as NSString).size(withAttributes: [NSAttributedString.Key.font: currentFont])
    
    while currentSize.width > label.frame.size.width && currentFont.pointSize > (originalFontSize * label.minimumScaleFactor) {
        currentFont = currentFont.withSize(currentFont.pointSize - 1.0)
        currentSize = (label.text! as NSString).size(withAttributes: [NSAttributedString.Key.font: currentFont])
    }
    
    return currentFont.pointSize
}
