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
    
    override func awakeFromNib() {
        clipsToBounds = true
        backgroundColor = .clear
    }
    
    @discardableResult
    func addSticker(image: UIImage, editable: Bool) -> StickerView {
        let sticker = StickerView(image: image)
        let size = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: CGPoint.zero, size: CGSize(width: 300, height: 300)))
        let constraints = CommonConstraints(centerX: sticker.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            centerY: sticker.centerYAnchor.constraint(equalTo: centerYAnchor),
                                            width: sticker.widthAnchor.constraint(equalToConstant: size.width),
                                            height: sticker.heightAnchor.constraint(equalToConstant: size.height))
        let layoutGuide = UILayoutGuide()
        let guideConstraints = CommonConstraints(centerX: layoutGuide.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            centerY: layoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor),
                                            width: layoutGuide.widthAnchor.constraint(equalToConstant: size.width),
                                            height: layoutGuide.heightAnchor.constraint(equalToConstant: size.height))

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
