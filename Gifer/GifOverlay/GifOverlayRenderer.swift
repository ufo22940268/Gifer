//
//  GifOverlayRenderer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class GifOverlayRenderer: UIView {

    let preferredStickerSize = CGSize(width: 180, height: 180)
    
    override func awakeFromNib() {
        clipsToBounds = true
        backgroundColor = .clear
    }
    
    
    @discardableResult
    func addSticker(image: UIImage, editable: Bool) -> StickerView {
        let sticker = StickerView(image: image)
        var stickerSize: CGSize
        if bounds.contains(CGRect(origin: CGPoint.zero, size: preferredStickerSize)) {
            stickerSize = preferredStickerSize
        } else {
            stickerSize = bounds.size
        }
        stickerSize = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: CGPoint.zero, size: stickerSize)).size
        let constraints = CommonConstraints(centerX: sticker.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            centerY: sticker.centerYAnchor.constraint(equalTo: centerYAnchor),
                                            width: sticker.widthAnchor.constraint(equalToConstant: stickerSize.width),
                                            height: sticker.heightAnchor.constraint(equalToConstant: stickerSize.height))
        let layoutGuide = UILayoutGuide()
        let guideConstraints = CommonConstraints(centerX: layoutGuide.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            centerY: layoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor),
                                            width: layoutGuide.widthAnchor.constraint(equalToConstant: stickerSize.width),
                                            height: layoutGuide.heightAnchor.constraint(equalToConstant: stickerSize.height))

        addSubview(sticker)
        addLayoutGuide(layoutGuide)
        constraints.activeAll()
        guideConstraints.activeAll()
        sticker.customConstraints = constraints
        sticker.guideConstraints = guideConstraints
        sticker.guide = layoutGuide
        
        if editable {
            sticker.registerEditRecognizer()
        }
        return sticker
    }
    
}
