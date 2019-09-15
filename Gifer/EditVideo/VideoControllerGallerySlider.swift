//
//  VideoControllerGallerySlider.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/31.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

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

class VideoControllerGallerySlider: UIScrollView {
    
    let frameHeight = CGFloat(36)
    let dividerHeight = CGFloat(2)
    let sliderHeight = CGFloat(12)
    
    var sliderWidthConstraint: NSLayoutConstraint!
    var sliderCenterXConstraint: NSLayoutConstraint!
    var galleryDuration: CMTime?
    var slider: UIView!
    lazy var sliderWrapper: UIView = {
        let view = UIView().useAutoLayout()
        return view
    }()
    var duration: CMTime?
    
    weak var customDelegate: VideoControllerGallerySliderDelegate?
    
    func setup() {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            superview.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            heightAnchor.constraint(equalToConstant: frameHeight),
            ])
        
        backgroundColor = .black
        layer.cornerRadius = sliderHeight/2
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        bounces = false
        delegate = self
        
        slider = VideoControllerGallerySliderButton()
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sliderWrapper)
        sliderWrapper.addSubview(slider)
        slider.backgroundColor = tintColor
        slider.layer.cornerRadius = sliderHeight/2
        sliderWidthConstraint = sliderWrapper.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            sliderWidthConstraint,
            sliderWrapper.heightAnchor.constraint(equalTo: heightAnchor),
            sliderWrapper.topAnchor.constraint(equalTo: topAnchor),
            sliderWrapper.bottomAnchor.constraint(equalTo: bottomAnchor),
            sliderWrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            sliderWrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider.leadingAnchor.constraint(equalTo: sliderWrapper.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: sliderWrapper.trailingAnchor),
            slider.centerYAnchor.constraint(equalTo: sliderWrapper.centerYAnchor),
            slider.heightAnchor.constraint(equalToConstant: sliderHeight)
            ])
    }
    
    override func tintColorDidChange() {
        if let slider = slider {
            slider.backgroundColor = tintColor
        }
    }
    
    func onVideoLoaded(galleryDuration: CMTime, duration: CMTime) {
        self.duration = duration
        layoutIfNeeded()
        updateSlider(begin: 0, end: CGFloat(galleryDuration.seconds/duration.seconds), duration: galleryDuration)
    }
    
    func updateSlider(begin: CGFloat, end: CGFloat, duration: CMTime) {
        self.galleryDuration = duration
        let leading = begin*bounds.width
        let trailing = end*bounds.width
        let width = trailing - leading
        
        contentInset = UIEdgeInsets(top: 0, left: bounds.width - width, bottom: 0, right: bounds.width - width)
//        contentOffset = CGPoint(x: bounds.width - width, y: 0)
        contentOffset = .zero
        sliderWidthConstraint.constant = width
    }
    
//    @objc func onChangeSlider(sender: UIPanGestureRecognizer) {
//        guard let duration = duration else { return }
//        let translation = sender.translation(in: self).x
//        let originCenterX = sliderCenterXConstraint.constant
//        let newCenterX = (sliderCenterXConstraint.constant + translation).clamped(to: sliderWidth/2...(bounds.width - sliderWidth/2))
//        let scrollDistance = newCenterX - originCenterX
//        customDelegate?.onTrimChangedByGallerySlider(state: sender.state,
//                                               scrollTime: CMTimeMultiplyByFloat64(duration, multiplier: Double((newCenterX - originCenterX)/bounds.width)),
//                                               scrollDistance: scrollDistance)
//        sliderCenterXConstraint.constant = newCenterX
//        sender.setTranslation(CGPoint.zero, in: self)
//    }
    
    func sync(galleryRange: GalleryRangePosition) {
        guard let duration = duration else { return }
        let center = (galleryRange.left.seconds + galleryRange.right.seconds)/2/duration.seconds
        let width = (galleryRange.right.seconds - galleryRange.left.seconds)/duration.seconds
        sliderCenterXConstraint.constant = bounds.width*CGFloat(center)
        sliderWidthConstraint.constant = bounds.width*CGFloat(width)
    }
}

//MARK: Gallery scroll delegate
extension VideoControllerGallerySlider: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard duration != nil else { return }
        let p = -contentOffset.x/frame.width
        customDelegate?.onScroll(self, leftPercentage: p, didEndDragging: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard duration != nil else { return }
        let p = -contentOffset.x/frame.width
        customDelegate?.onScroll(self, leftPercentage: p, didEndDragging: true)
    }
}

protocol VideoControllerGallerySliderDelegate: class {
    func onScroll(_ slider: VideoControllerGallerySlider, leftPercentage: CGFloat, didEndDragging: Bool)
}
