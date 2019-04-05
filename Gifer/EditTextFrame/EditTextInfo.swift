//
//  EditTextInfo.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

struct EditTextInfo: OverlayRenderInfo {
    var text: String
    var fontName: String
    var textColor: UIColor
    var nRect: CGRect?
    
    var cropSize: CGSize?
    var fontSize: CGFloat?
    
    static let preferredTextSize = CGFloat(30)
    
    static var initial: EditTextInfo {
        return EditTextInfo(text: "", fontName: UIFont.systemFont(ofSize: 12).fontName, textColor: .white)
    }
    
    init(text: String, fontName: String, textColor: UIColor) {
        self.text = text
        self.fontName = fontName
        self.textColor = textColor
    }
    
    func fixTextRect(videoSize: CGSize, cropArea: CGRect) -> EditTextInfo {
        var newInfo = self
        newInfo.cropSize = cropArea.realRect(containerSize: videoSize).size
        newInfo.nRect = convertComponentRectByCrop(originRect: nRect!, videoSize: videoSize, cropArea: cropArea)
        return newInfo
    }
    
    func createExportLabelView(imageSize: CGSize) -> UILabel {
        let labelView = UILabel()
        let scale = imageSize.width/cropSize!.width
        let exportFontSize = scale*fontSize!
        labelView.text = text
        labelView.font = UIFont(name: fontName, size: exportFontSize)
        labelView.textColor = textColor
        return labelView
    }
}

