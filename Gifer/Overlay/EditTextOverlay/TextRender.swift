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
    
    var renderImage: UIImage {
        return renderToImage(afterScreenUpdates: true)
    }
    
    var attachText: String? {
        if let text = text, text.count > 3 {
            return String(text.prefix(3))
        } else {
            return text
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
    
    var fontSize: CGFloat {
        return approximateAdjustedFontSizeWithLabel(self)
    }
    
    init(info: EditTextInfo) {
        super.init(frame: .zero)
        defer {
            self.info = info
        }
        baselineAdjustment = .alignCenters
        useAutoLayout()
        minimumScaleFactor = 0.05
        adjustsFontSizeToFitWidth = true
        textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func copy() -> OverlayComponentRender {
        return TextRender(info: self.info)
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
