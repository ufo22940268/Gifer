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

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension UIImage {
    func draw(centerIn rect: CGRect) {
        let origin = CGPoint(x: rect.midX - size.width/2, y: rect.midY - size.height/2)
        return draw(in: CGRect(origin: origin, size: size))
    }
}

class VideoGallery: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setup() {
        alignment = .center
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.layoutMarginsGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.layoutMarginsGuide.trailingAnchor),
            topAnchor.constraint(equalTo: superview!.layoutMarginsGuide.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.layoutMarginsGuide.bottomAnchor)
            ])
    }
    
    func addImage(_ image: UIImage, totalCount: Int) -> Void {
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -VideoControllerConstants.topAndBottomInset*2),
            imageView.widthAnchor.constraint(equalToConstant: self.bounds.width/CGFloat(totalCount)),
            ])
        imageView.contentMode = .scaleAspectFill
    }
}

protocol VideoProgressDelegate: class {
    func onProgressChanged(progress: CGFloat)
}

class VideoTrim: UIControl {

    var leftArrow: UIImage = {
        return #imageLiteral(resourceName: "arrow-ios-back-outline.png")
    }()
    
    var rightArrow: UIImage = {
        return #imageLiteral(resourceName: "arrow-ios-forward-outline.png")
    }()
    
    var leftTrim: UIImageView! = {
        let leftTrim = UIImageView()
        leftTrim.translatesAutoresizingMaskIntoConstraints = false
        leftTrim.backgroundColor = UIColor.yellow
        leftTrim.image = #imageLiteral(resourceName: "arrow-ios-back-outline.png")
        leftTrim.contentMode = .center
        return leftTrim
    }()
    
    var rightTrim: UIImageView! = {
        let rightTrim = UIImageView()
        rightTrim.translatesAutoresizingMaskIntoConstraints = false
        rightTrim.backgroundColor = UIColor.yellow
        rightTrim.image = #imageLiteral(resourceName: "arrow-ios-forward-outline.png")
        rightTrim.contentMode = .center
        return rightTrim
    }()

    var mainColor: UIColor {
        return UIColor.yellow
    }
    
    func setup() {
        guard let superview = superview else {
            return
        }
        
        isOpaque = false
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)])
        
        addSubview(leftTrim)
        NSLayoutConstraint.activate([
            leftTrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftTrim.topAnchor.constraint(equalTo: topAnchor),
            leftTrim.heightAnchor.constraint(equalTo: heightAnchor),
            leftTrim.widthAnchor.constraint(equalToConstant: VideoControllerConstants.trimWidth)])
        
        addSubview(rightTrim)
        NSLayoutConstraint.activate([
            rightTrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightTrim.topAnchor.constraint(equalTo: topAnchor),
            rightTrim.heightAnchor.constraint(equalTo: heightAnchor),
            rightTrim.widthAnchor.constraint(equalToConstant: VideoControllerConstants.trimWidth)])
    }
    
    override func draw(_ rect: CGRect) {
        let color = UIColor.yellow
        color.setStroke()
        let framePath = UIBezierPath(rect: rect)
        framePath.lineWidth = VideoControllerConstants.topAndBottomInset
        framePath.stroke()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if point.x > leftTrim.frame.maxX && point.x < rightTrim.frame.minX {
            return nil
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }
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
        let slideGesture = UIPanGestureRecognizer(target: self, action: #selector(onDrag(gesture:)))
        addGestureRecognizer(slideGesture)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear
        isOpaque = false
        leadingConstraint = leadingAnchor.constraint(equalTo: superview!.leadingAnchor)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: superview!.heightAnchor, multiplier: 1/CGFloat(5)),
            heightAnchor.constraint(equalTo: superview!.heightAnchor),
            topAnchor.constraint(equalTo: superview!.topAnchor),
            leadingConstraint
            ])
        self.layer.addSublayer(shapeLayer)
    }
    
    @objc func onDrag(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        updateProgress(translationX: translation.x)
        gesture.setTranslation(CGPoint.zero, in: superview)
    }
    
    
    override func layoutSublayers(of layer: CALayer) {
        let path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.bounds.width/2)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
    }
    
    func updateProgress(translationX: CGFloat) -> Void {
        let rightThreshold = (superview!.bounds.width - bounds.width)
        let newConstant = leadingConstraint.constant + translationX
        leadingConstraint.constant = newConstant.clamped(to: 0...rightThreshold)
        self.progress = leadingConstraint.constant/rightThreshold
    }
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(10)
    static var topAndBottomInset = CGFloat(4)
}

class VideoController: UIView {
    var galleryView: VideoGallery!
    var progressSlider: VideoProgressSlider!
    var videoTrim: VideoTrim!
    
    var slideDelegate: VideoProgressDelegate? {
        get {
            return progressSlider.delegate
        }
        set {
            progressSlider.delegate = newValue
        }
    }
    
    override func awakeFromNib() {
        layoutMargins.top = 0
        layoutMargins.bottom = 0
        layoutMargins.left = VideoControllerConstants.trimWidth
        layoutMargins.right = VideoControllerConstants.trimWidth

        galleryView = VideoGallery(frame: CGRect.zero)
        addSubview(galleryView)
        galleryView.setup()
        
        progressSlider = VideoProgressSlider()
        galleryView.addSubview(progressSlider)
        progressSlider.setup()
        
        videoTrim = VideoTrim()
        addSubview(videoTrim)
        videoTrim.setup()
    }
    
    fileprivate func loadGallery(withImages images: [UIImage]) -> Void {
        for image in images {
            galleryView.addImage(image, totalCount: images.count)
        }
        
        galleryView.bringSubviewToFront(progressSlider)
        
        //Not good implementation to change background color. Because the background is set by UIAppearance, so should find better way to overwrite it.
        videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        let thumbernails = playerItem.asset.extractThumbernails()
        loadGallery(withImages: thumbernails)
    }
}
