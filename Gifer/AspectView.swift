//
//  AspectView.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/6.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class AspectView: UIView {
    
    var imageView: UIImageView!
    
    init(frame: CGRect, image: UIImage) {
        super.init(frame: frame)
        clipsToBounds = true
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func makeImageViewFitContainer() {
        guard let imageSize = imageView.image?.size else {
            return
        }
        
        let imageRatio = imageSize.width/imageSize.height
        let containerRatio = bounds.width/bounds.height
        var imageViewSize: CGSize
        var imageViewOrigin: CGPoint
        if imageRatio > containerRatio {
            imageViewSize = CGSize(width: frame.width, height: imageSize.height/imageSize.width*frame.width)
            imageViewOrigin = CGPoint(x: 0, y: (frame.height - imageViewSize.height)/2)
        } else {
            imageViewSize = CGSize(width: frame.height*(imageSize.width/imageSize.height), height: frame.height)
            imageViewOrigin = CGPoint(x: (frame.width - imageViewSize.width)/2, y: 0)
        }
        imageView.frame = CGRect(origin: imageViewOrigin, size: imageViewSize)
    }
    
    func makeImageViewFillContainer() {
        imageView.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
    }
}
