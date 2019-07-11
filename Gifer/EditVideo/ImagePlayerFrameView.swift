//
//  ImagePlayerFrameView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class ImagePlayerFrameView: UIView {
    
    var cropArea: CGRect?
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    
    var image: UIImage? {
        set(newImage) {
            imageView.image = newImage
            setNeedsLayout()
        }
        
        get {
            return imageView.image
        }
    }
    
    lazy var frameView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(frameView)
        frameView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = image else { return }
        
        let cropArea = self.cropArea ?? CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        
        let cropAreaInView = AVMakeRect(aspectRatio: cropArea.size.applying(CGAffineTransform(scaleX: image.size.width, y: image.size.height)), insideRect: bounds)
        frameView.frame = cropAreaInView
        
        let imageSizeInView = CGSize(width: cropAreaInView.width/cropArea.width*1, height: cropAreaInView.height/cropArea.height*1)
        var imageOriginInView = CGPoint(x: imageSizeInView.width*cropArea.origin.x, y: imageSizeInView.height*cropArea.origin.y)
        imageOriginInView = cropAreaInView.origin.applying(CGAffineTransform(translationX: -imageOriginInView.x, y: -imageOriginInView.y))        
        imageView.frame = convert(CGRect(origin: imageOriginInView, size: imageSizeInView), to: frameView)
    }
}
