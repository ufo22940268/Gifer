//
//  VideoControllerGallerySlider.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/31.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

protocol VideoControllerGallerySliderDelegate: class {
    func onTrimChangedByGallerySlider(state: UIGestureRecognizer.State, scrollTime: CMTime, scrollDistance: CGFloat)
}

private class VideoControllerGallerySliderButton: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        let leftArrow = UIImageView()
        leftArrow.translatesAutoresizingMaskIntoConstraints = false
        leftArrow.image = #imageLiteral(resourceName: "arrow-ios-back-outline.png")
        leftArrow.contentMode = .scaleAspectFit
        leftArrow.tintColor = .white
        addSubview(leftArrow)
        NSLayoutConstraint.activate([
            leftArrow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            leftArrow.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftArrow.heightAnchor.constraint(equalTo: heightAnchor, constant: -4)])
        
        let rightArrow = UIImageView()
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        rightArrow.image = #imageLiteral(resourceName: "arrow-ios-forward-outline.png")
        rightArrow.contentMode = .scaleAspectFit
        rightArrow.tintColor = .white
        addSubview(rightArrow)
        NSLayoutConstraint.activate([
            rightArrow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            rightArrow.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightArrow.heightAnchor.constraint(equalTo: heightAnchor, constant: -4)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VideoControllerGallerySlider: UIView {
    
    let frameHeight = CGFloat(28)
    let dividerHeight = CGFloat(2)
    let sliderHeight = CGFloat(12)
    
    let mainColor = UIColor(named: "mainColor")
    
    var sliderWidthConstraint: NSLayoutConstraint!
    var sliderCenterXConstraint: NSLayoutConstraint!
    var galleryDuration: CMTime?
    var slider: UIView!
    var duration: CMTime?
    
    weak var delegate: VideoControllerGallerySliderDelegate?
    
    func setup() {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            superview.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            heightAnchor.constraint(equalToConstant: frameHeight),
            ])
        
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        NSLayoutConstraint.activate([
            background.heightAnchor.constraint(equalToConstant: sliderHeight),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        background.backgroundColor = .black
        background.layer.cornerRadius = sliderHeight/2
        
        slider = VideoControllerGallerySliderButton()
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slider)
        slider.backgroundColor = UIColor(named: "mainColor")
        slider.layer.cornerRadius = sliderHeight/2
        sliderWidthConstraint = slider.widthAnchor.constraint(equalToConstant: 0)
        sliderCenterXConstraint = slider.centerXAnchor.constraint(equalTo: leadingAnchor)
        NSLayoutConstraint.activate([
            sliderWidthConstraint,
            sliderCenterXConstraint,
            slider.heightAnchor.constraint(equalToConstant: sliderHeight),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        slider.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onChangeSlider(sender:))))
    }
    
    func onVideoLoaded(galleryDuration: CMTime, duration: CMTime) {
        self.duration = duration
        layoutIfNeeded()
        updateSlider(begin: 0, end: CGFloat(galleryDuration.seconds/duration.seconds), duration: galleryDuration)
    }
    
    var sliderWidth: CGFloat {
        return sliderWidthConstraint.constant
    }
    
    func updateSlider(begin: CGFloat, end: CGFloat, duration: CMTime) {
        self.galleryDuration = duration
        let leading = begin*bounds.width
        let trailing = end*bounds.width
        let centerX = (trailing + leading)/2
        let width = trailing - leading
        sliderCenterXConstraint.constant = centerX
        sliderWidthConstraint.constant = width
    }
    
    @objc func onChangeSlider(sender: UIPanGestureRecognizer) {
        guard let duration = duration else { return }
        let translation = sender.translation(in: self).x
        let originCenterX = sliderCenterXConstraint.constant
        let newCenterX = (sliderCenterXConstraint.constant + translation).clamped(to: sliderWidth/2...(bounds.width - sliderWidth/2))
        let scrollDistance = newCenterX - originCenterX
        delegate?.onTrimChangedByGallerySlider(state: sender.state,
                                               scrollTime: CMTimeMultiplyByFloat64(duration, multiplier: Double((newCenterX - originCenterX)/bounds.width)),
                                               scrollDistance: scrollDistance)
        sliderCenterXConstraint.constant = newCenterX
        sender.setTranslation(CGPoint.zero, in: self)
    }
    
//    var galleryRange: GalleryRangePosition {
//        guard let duration = duration else { fatalError() }
//        let width = bounds.width
//        let leading = CMTimeMultiplyByFloat64(duration, multiplier: Double(slider.frame.minX/width))
//        let trailing = CMTimeMultiplyByFloat64(duration, multiplier: Double(slider.frame.maxX/width))
//        return GalleryRangePosition(left: leading, right: trailing)
//    }
    
    func sync(galleryRange: GalleryRangePosition) {
        guard let duration = duration else { return }
        let center = (galleryRange.left.seconds + galleryRange.right.seconds)/2/duration.seconds
        let width = (galleryRange.right.seconds - galleryRange.left.seconds)/duration.seconds
        sliderCenterXConstraint.constant = bounds.width*CGFloat(center)
        sliderWidthConstraint.constant = bounds.width*CGFloat(width)
    }
}
