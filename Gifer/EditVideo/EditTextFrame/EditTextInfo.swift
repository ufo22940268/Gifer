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
    
    func createExportLabelView(imageSize: CGSize) -> UILabel {
        let labelView = UILabel()
        let scale = imageSize.width/videoSize!.width
        let exportFontSize = scale*fontSize!
        labelView.text = text
        labelView.textAlignment = .center
        labelView.baselineAdjustment = .alignCenters
        labelView.font = UIFont(name: fontName, size: exportFontSize)
        labelView.textColor = textColor
        labelView.backgroundColor = .clear
        labelView.sizeToFit()
        return labelView
    }
}

