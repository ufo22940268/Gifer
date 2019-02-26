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
    func onTrimChanged(begin: CGFloat, end: CGFloat, state: UIGestureRecognizer.State)
}

class VideoControllerGallerySlider: UIView {
    
    let frameHeight = CGFloat(28)
    let dividerHeight = CGFloat(2)
    let sliderHeight = CGFloat(8)
    
    let mainColor = UIColor(named: "mainColor")
    
    var sliderWidthConstraint: NSLayoutConstraint!
    var sliderCenterXConstraint: NSLayoutConstraint!
    var galleryDuration: CMTime?
    var duration: CMTime?
    
    weak var delegate: VideoControllerGallerySliderDelegate?
    
    func setup() {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            superview.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            heightAnchor.constraint(equalToConstant: frameHeight),
            ])
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: dividerHeight),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        divider.backgroundColor = mainColor
        
        let slider = UIView()
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slider)
        slider.backgroundColor = UIColor(named: "mainColor")
        slider.layer.cornerRadius = sliderHeight/3
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
        self.galleryDuration = galleryDuration
        self.duration = duration
        self.sliderWidthConstraint.constant = CGFloat(galleryDuration.seconds/duration.seconds)*bounds.width
        layoutIfNeeded()
    }
    
    func updateSlider(begin: CGFloat, end: CGFloat) {
        sliderCenterXConstraint.constant = (end + begin)/2*bounds.width
    }
    
    @objc func onChangeSlider(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self).x
        let sliderWidth = sliderWidthConstraint.constant
        sliderCenterXConstraint.constant = (sliderCenterXConstraint.constant + translation).clamped(to: sliderWidth/2...(bounds.width - sliderWidth/2))
        sender.setTranslation(CGPoint.zero, in: self)
        
        let centerX = sliderCenterXConstraint.constant
        delegate?.onTrimChanged(begin: (centerX - sliderWidth/2)/bounds.width, end: (centerX + sliderWidth/2)/bounds.width, state: sender.state)
    }
}
