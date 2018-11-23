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
    
    let faderBackgroundColor = UIColor(white: 0.7, alpha: 0.4)
    
    lazy var leftFader: UIView = {
        let left = UIView()
        left.translatesAutoresizingMaskIntoConstraints = false
        left.backgroundColor = faderBackgroundColor
        return left
    }()
    
    lazy var rightFader: UIView = {
        let right = UIView()
        right.translatesAutoresizingMaskIntoConstraints = false
        right.backgroundColor = faderBackgroundColor
        return right
    }()
    var leftFaderWidthConstraint: NSLayoutConstraint!
    var rightFaderWidthConstraint: NSLayoutConstraint!

    func setup() {
        alignment = .center
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.layoutMarginsGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.layoutMarginsGuide.trailingAnchor),
            topAnchor.constraint(equalTo: superview!.layoutMarginsGuide.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.layoutMarginsGuide.bottomAnchor)
            ])
        
        addSubview(leftFader)
        leftFaderWidthConstraint = leftFader.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            leftFaderWidthConstraint,
            leftFader.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftFader.topAnchor.constraint(equalTo: topAnchor),
            leftFader.heightAnchor.constraint(equalTo: heightAnchor)])
        
        addSubview(rightFader)
        rightFaderWidthConstraint = rightFader.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            rightFaderWidthConstraint,
            rightFader.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightFader.topAnchor.constraint(equalTo: topAnchor),
            rightFader.heightAnchor.constraint(equalTo: heightAnchor)])
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
    
    func updateByTrim(trimPosition position: VideoTrimPosition) {
        leftFaderWidthConstraint.constant = position.leftTrim*bounds.width
        rightFaderWidthConstraint.constant = bounds.width - position.rightTrim*bounds.width
    }
}

protocol VideoProgressDelegate: class {
    func onProgressChanged(progress: CGFloat)
}

protocol SlideVideoProgressDelegate: class {
    func onSlideVideo(progress: CGFloat)
}

protocol VideoTrimDelegate: class {
    func onTrimChanged(position: VideoTrimPosition)
}

struct VideoTrimPosition {
    
    /// Propotional to video duration. Ranged from 0 to 1
    var leftTrim: CGFloat
    
    /// Propotional to video duration. Ranged from 0 to 1
    var rightTrim: CGFloat
    
    static var initialState: VideoTrimPosition {
        return VideoTrimPosition(leftTrim: 0, rightTrim: 1)
    }
}

class VideoTrim: UIControl {

    var leftArrow: UIImage = {
        return #imageLiteral(resourceName: "arrow-ios-back-outline.png")
    }()
    
    var rightArrow: UIImage = {
        return #imageLiteral(resourceName: "arrow-ios-forward-outline.png")
    }()
    
    var leftTrimLeadingConstraint: NSLayoutConstraint!
    var rightTrimTrailingConstraint: NSLayoutConstraint!
    let minimunGapBetweenLeftTrimAndRightTrim = CGFloat(50)
    
    var topLine: UIView!
    var bottomLine: UIView!
    
    weak var trimDelegate: VideoTrimDelegate?

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
        
        //Setup trims
        addSubview(leftTrim)
        leftTrimLeadingConstraint = leftTrim.leadingAnchor.constraint(equalTo: leadingAnchor)
        NSLayoutConstraint.activate([
            leftTrimLeadingConstraint,
            leftTrim.topAnchor.constraint(equalTo: topAnchor),
            leftTrim.heightAnchor.constraint(equalTo: heightAnchor),
            leftTrim.widthAnchor.constraint(equalToConstant: VideoControllerConstants.trimWidth)])
        leftTrim.isUserInteractionEnabled = true
        leftTrim.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onLeftTrimDragged(recognizer:))))
        
        addSubview(rightTrim)
        rightTrimTrailingConstraint = rightTrim.trailingAnchor.constraint(equalTo: trailingAnchor)
        NSLayoutConstraint.activate([
            rightTrimTrailingConstraint,
            rightTrim.topAnchor.constraint(equalTo: topAnchor),
            rightTrim.heightAnchor.constraint(equalTo: heightAnchor),
            rightTrim.widthAnchor.constraint(equalToConstant: VideoControllerConstants.trimWidth)])
        rightTrim.isUserInteractionEnabled = true
        rightTrim.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onRightTrimDragged(recognizer:))))
        
        //Setup top line and bottom line
        topLine = UIView()
        topLine.translatesAutoresizingMaskIntoConstraints = false
        topLine.backgroundColor = mainColor
        addSubview(topLine)
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.heightAnchor.constraint(equalToConstant: VideoControllerConstants.topAndBottomInset),
            topLine.leadingAnchor.constraint(equalTo: leftTrim.trailingAnchor),
            topLine.trailingAnchor.constraint(equalTo: rightTrim.leadingAnchor)])

        
        bottomLine = UIView()
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.backgroundColor = mainColor
        addSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: VideoControllerConstants.topAndBottomInset),
            bottomLine.leadingAnchor.constraint(equalTo: leftTrim.trailingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: rightTrim.leadingAnchor)])
    }
    
    @objc func onLeftTrimDragged(recognizer: UIPanGestureRecognizer) {
        let translate = recognizer.translation(in: self)
        let maxLeftLeading = bounds.width - minimunGapBetweenLeftTrimAndRightTrim - abs(rightTrimTrailingConstraint.constant)
        let newConstant = leftTrimLeadingConstraint.constant + translate.x
        leftTrimLeadingConstraint.constant = newConstant.clamped(to: 0...maxLeftLeading)
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        triggerTrimDelegate()
    }
    
    @objc func onRightTrimDragged(recognizer: UIPanGestureRecognizer) {
        let translate = recognizer.translation(in: self)
        let minRightTrailing = -(bounds.width - minimunGapBetweenLeftTrimAndRightTrim - leftTrimLeadingConstraint.constant)
        let newConstant = rightTrimTrailingConstraint.constant + translate.x
        rightTrimTrailingConstraint.constant = newConstant.clamped(to: minRightTrailing...0)
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        triggerTrimDelegate()
    }
    
    var trimRange: CGFloat {
        return bounds.width - VideoControllerConstants.trimWidth
    }
    
    func triggerTrimDelegate() {
        let trimPosition = VideoTrimPosition(leftTrim: leftTrimLeadingConstraint.constant/trimRange, rightTrim: (trimRange - abs(rightTrimTrailingConstraint.constant))/trimRange)
        trimDelegate?.onTrimChanged(position: trimPosition)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if point.x > leftTrim.frame.maxX && point.x < rightTrim.frame.minX {
            return nil
        } else {
            let v = super.hitTest(point, with: event)
            return v
        }
    }
}

class VideoProgressSlider: UIControl {
    
    var delegate: SlideVideoProgressDelegate?
    var progress: CGFloat = 0

    lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    var leadingConstraint: NSLayoutConstraint!
    var activeLeadingConstraint: NSLayoutConstraint!
    var activeTrailingConstraint: NSLayoutConstraint!
    var sliderRangeGuide: UILayoutGuide!
    var sliderActiveRangeGuide: UILayoutGuide!

    fileprivate func setupGuides(trimView: VideoTrim) {
        guard let superview = superview else { return }
        sliderRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderRangeGuide)
        NSLayoutConstraint.activate([
            sliderRangeGuide.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: VideoControllerConstants.trimWidth),
            sliderRangeGuide.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -VideoControllerConstants.trimWidth - VideoControllerConstants.sliderWidth),
            ])
        
        sliderActiveRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderActiveRangeGuide)
        activeLeadingConstraint = sliderActiveRangeGuide.leadingAnchor.constraint(equalTo: trimView.leftTrim.trailingAnchor)
        activeLeadingConstraint.isActive = true
        activeTrailingConstraint = sliderActiveRangeGuide.trailingAnchor.constraint(equalTo: trimView.rightTrim.leadingAnchor, constant: -VideoControllerConstants.sliderWidth)
        activeTrailingConstraint.isActive = true
    }
    
    func setup(trimView: VideoTrim) -> Void {
        guard let superview = superview else { return  }
        
        setupGuides(trimView: trimView)
        
        let slideGesture = UIPanGestureRecognizer(target: self, action: #selector(onDrag(gesture:)))
        addGestureRecognizer(slideGesture)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear
        isOpaque = false
        leadingConstraint = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: VideoControllerConstants.trimWidth)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: VideoControllerConstants.sliderWidth),
            heightAnchor.constraint(equalTo: superview.heightAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            leadingConstraint
            ])
        self.layer.addSublayer(shapeLayer)
        
    }
    
    @objc func onDrag(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        shiftProgress(translationX: translation.x)
        gesture.setTranslation(CGPoint.zero, in: superview)
    }
    
    
    override func layoutSublayers(of layer: CALayer) {
        let path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.bounds.width/2)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
    }
    
    var slidableRange:CGFloat {
        return sliderRangeGuide.layoutFrame.width
    }
    
    var maxLeading: CGFloat {
        return sliderActiveRangeGuide.layoutFrame.maxX
    }
    
    var minLeading: CGFloat {
        return sliderActiveRangeGuide.layoutFrame.minX
    }

    fileprivate func shiftProgress(translationX: CGFloat) -> Void {
        let newConstant = leadingConstraint.constant + translationX
        leadingConstraint.constant = newConstant.clamped(to: minLeading...maxLeading)
        self.progress = leadingConstraint.constant/slidableRange
        slideVideo()
    }
    
    func updateProgress(progress: CGFloat) {
        let progress = progress.clamped(to: 0...CGFloat(1))
        leadingConstraint.constant = slidableRange*progress
        self.progress = progress
    }
    
    func slideVideo() {
        delegate?.onSlideVideo(progress: progress)
    }
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(10)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(10)
}

class VideoController: UIView {
    var galleryView: VideoGallery!
    var progressSlider: VideoProgressSlider!
    var videoTrim: VideoTrim!
    
    var slideDelegate: SlideVideoProgressDelegate? {
        get {
            return progressSlider.delegate
        }
        set {
            progressSlider.delegate = newValue
        }
    }
    
    override func awakeFromNib() {
        backgroundColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)

        layoutMargins.top = 0
        layoutMargins.bottom = 0
        layoutMargins.left = 0
        layoutMargins.right = 0

        galleryView = VideoGallery(frame: CGRect.zero)
        addSubview(galleryView)
        galleryView.setup()
        
        videoTrim = VideoTrim()
        addSubview(videoTrim)
        videoTrim.setup()
        
        progressSlider = VideoProgressSlider()
        galleryView.addSubview(progressSlider)
        progressSlider.setup(trimView: videoTrim)
    }
    
    fileprivate func loadGallery(withImages images: [UIImage]) -> Void {
        for image in images {
            galleryView.addImage(image, totalCount: images.count)
        }
        
        galleryView.bringSubviewToFront(progressSlider)
        galleryView.bringSubviewToFront(galleryView.leftFader)
        galleryView.bringSubviewToFront(galleryView.rightFader)

        //Not good implementation to change background color. Because the background is set by UIAppearance, so should find better way to overwrite it.
        videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        let thumbernails = playerItem.asset.extractThumbernails()
        loadGallery(withImages: thumbernails)
    }
    
    func updateSliderProgress(_ progress: CGFloat) {
        progressSlider.updateProgress(progress: progress)
    }
    
    func updateTrim(position: VideoTrimPosition) {
        galleryView.updateByTrim(trimPosition: position)
    }
}
