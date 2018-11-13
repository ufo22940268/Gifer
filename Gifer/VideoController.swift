//
//  VideoController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoGallery: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func addImage(_ image: UIImage, totalCount: Int) -> Void {
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
            imageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/CGFloat(totalCount))
            ])
        imageView.contentMode = .scaleAspectFill
    }
}

protocol VideoProgressDelegate: class {
    func onProgressChanged(progress: CGFloat)
}

class VideoProgressSlider: UIControl {
    
    var delegate: VideoProgressDelegate?
    var progress: CGFloat = 0 {
        didSet {
            delegate?.onProgressChanged(progress: progress)
        }
    }
    lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    var leadingConstraint: NSLayoutConstraint!

    func setup() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        leadingConstraint = leadingAnchor.constraint(equalTo: superview!.leadingAnchor)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: superview!.heightAnchor, multiplier: 1/CGFloat(5)),
            heightAnchor.constraint(equalTo: superview!.heightAnchor),
            topAnchor.constraint(equalTo: superview!.topAnchor),
            leadingConstraint
            ])
        self.layer.addSublayer(shapeLayer)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        let path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.bounds.width/2)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.yellow.cgColor
    }
    
    func updateProgress(_ progress: CGFloat) -> Void {
        let halfWidth = bounds.width/2
        var leading: CGFloat
        let progress = progress*superview!.bounds.width
        if progress < halfWidth {
            leading = 0
        } else if progress > superview!.bounds.width - halfWidth*2 {
            leading = superview!.bounds.width - halfWidth*2
        } else {
            leading = progress + halfWidth
        }
        leadingConstraint.constant = leading
        
        self.progress = leading/(superview!.bounds.width - halfWidth*2)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let position = touch.location(in: superview)
        updateProgress(CGFloat(position.x)/superview!.bounds.width)
        return true
    }
}

class VideoController: UIView {
    var galleryView: VideoGallery!
    var progressSlider: VideoProgressSlider!
    
    var slideDelegate: VideoProgressDelegate? {
        get {
            return progressSlider.delegate
        }
        set {
            progressSlider.delegate = newValue
        }
    }
    
    override func awakeFromNib() {
        UIView.appearance(for: traitCollection).backgroundColor = UIColor.black

        galleryView = VideoGallery(frame: CGRect.zero)
        addSubview(galleryView)
        NSLayoutConstraint.activate([
            galleryView.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryView.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            galleryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ])
        
        progressSlider = VideoProgressSlider()
        addSubview(progressSlider)
        progressSlider.setup()
    }
    
    fileprivate func loadGallery(withImages images: [UIImage]) -> Void {
        for image in images {
            galleryView.addImage(image, totalCount: images.count)
        }
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        let thumbernails = playerItem.asset.extractThumbernails()
        loadGallery(withImages: thumbernails)
    }
}
