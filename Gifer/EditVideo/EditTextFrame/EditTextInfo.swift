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
    var rotation: CGFloat
    
    var cropSize: CGSize?
    var fontSize: CGFloat?
    
    /// Fixit: Seems deprecated
    var videoSize: CGSize?
    
    var trimPosition: VideoTrimPosition!
    
    static let preferredTextSize = CGFloat(30)
    
    static var initial: EditTextInfo {
        return EditTextInfo(text: "", fontName: UIFont.systemFont(ofSize: 12).fontName, textColor: .white)
    }
    
    init(text: String, fontName: String, textColor: UIColor, rotation: CGFloat = 0) {
        self.text = text
        self.fontName = fontName
        self.textColor = textColor
        self.rotation = rotation
    }
    
    func fixTextRect(videoSize: CGSize, cropArea: CGRect) -> EditTextInfo {
        var newInfo = self
        newInfo.videoSize = videoSize
        newInfo.cropSize = cropArea.realRect(containerSize: videoSize).size
        newInfo.nRect = convertComponentRectByCrop(originRect: nRect!, videoSize: videoSize, cropArea: cropArea)
        return newInfo
    }
    
    func createExportLabelView(imageSize: CGSize, fontRect: CGRect) -> UILabel {
        let labelView = UILabel()
        labelView.text = text
        labelView.textAlignment = .center
        labelView.baselineAdjustment = .alignCenters
        labelView.font = UIFont(name: fontName, size: 50)
        labelView.textColor = textColor
        labelView.backgroundColor = .clear
        labelView.frame = CGRect(origin: .zero, size: fontRect.size)
        
        let calibratedFontSize = approximateAdjustedFontSizeWithLabel(labelView)
        labelView.font = UIFont(name: fontName, size: calibratedFontSize)
        
        return labelView
    }
}
