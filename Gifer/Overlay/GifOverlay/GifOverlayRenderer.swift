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
    var stickerViews = [StickerView]()
    var stickers: [StickerInfo] {
        return stickerViews.map {$0.sticker}
    }
    
    override func awakeFromNib() {
        clipsToBounds = true
        backgroundColor = .clear
    }
    
    var editable: Bool = false {
        didSet {
            stickerViews.forEach {$0.isUserInteractionEnabled = editable}
        }
    }
    
    
    @discardableResult
    func addSticker(image: UIImage, editable: Bool) -> StickerView {
        let sticker = StickerInfo(image: image)
        let stickerView = StickerView(image: image, sticker: sticker)
        var stickerSize: CGSize
        if bounds.contains(CGRect(origin: CGPoint.zero, size: preferredStickerSize)) {
            stickerSize = preferredStickerSize
        } else {
            stickerSize = bounds.size
        }
        stickerSize = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: CGPoint.zero, size: stickerSize)).size
        let constraints = CommonConstraints(centerX: stickerView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            centerY: stickerView.centerYAnchor.constraint(equalTo: centerYAnchor),
                                            width: stickerView.widthAnchor.constraint(equalToConstant: stickerSize.width),
                                            height: stickerView.heightAnchor.constraint(equalToConstant: stickerSize.height))
        let layoutGuide = UILayoutGuide()
        let guideConstraints = CommonConstraints(centerX: layoutGuide.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            centerY: layoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor),
                                            width: layoutGuide.widthAnchor.constraint(equalToConstant: stickerSize.width),
                                            height: layoutGuide.heightAnchor.constraint(equalToConstant: stickerSize.height))

        addSubview(stickerView)
        addLayoutGuide(layoutGuide)
        constraints.activeAll()
        guideConstraints.activeAll()
        stickerView.customConstraints = constraints
        stickerView.guideConstraints = guideConstraints
        stickerView.guide = layoutGuide
        stickerView.registerEditRecognizer()
        
        self.editable = editable
        
        stickerViews.append(stickerView)
        return stickerView
    }
    
    func removeSticker(_ stickerView: StickerView) {
        stickerView.removeFromSuperview()
        stickerViews.remove(at: stickerViews.firstIndex(of: stickerView)!)
    }
}
