//
//  VideoProgressSlider.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoControllerSlider: UIControl {
    
    weak var delegate: SlideVideoProgressDelegate?
    var duration: CMTime!
    
    lazy var sliderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    var leadingConstraint: NSLayoutConstraint!
    var sliderRangeGuide: UILayoutGuide!
    var trimView: VideoControllerTrim!
    var currentPosition: CMTime {
        superview!.layoutIfNeeded()
        let percentage = (frame.minX - sliderRangeGuide.layoutFrame.minX)/sliderRangeGuide.layoutFrame.width
        return trimView.trimPosition.getSliderPosition(sliderRelativeToTrim: percentage)
    }
        
    fileprivate func setupGuides(trimView: VideoControllerTrim) {
        guard let superview = superview else { return }
        
        sliderRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderRangeGuide)
        let activeLeadingConstraint = sliderRangeGuide.leadingAnchor.constraint(equalTo: trimView.leftTrim.trailingAnchor)
        activeLeadingConstraint.isActive = true
        let activeTrailingConstraint = sliderRangeGuide.trailingAnchor.constraint(equalTo: trimView.rightTrim.leadingAnchor, constant:-VideoControllerConstants.sliderWidth)
        activeTrailingConstraint.isActive = true
    }
    
    func setup(trimView: VideoControllerTrim) -> Void {
        guard let superview = superview else { return  }
        
        setupGuides(trimView: trimView)
        self.trimView = trimView
        trimView.slider = self
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
        leadingConstraint = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0)
        leadingConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: VideoControllerConstants.sliderWidth),
            heightAnchor.constraint(equalTo: superview.heightAnchor, constant: 8),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            leadingConstraint,
            leadingAnchor.constraint(greaterThanOrEqualTo: sliderRangeGuide.leadingAnchor),
            leadingAnchor.constraint(lessThanOrEqualTo: sliderRangeGuide.trailingAnchor)
            ])
        layer.cornerRadius = 4
    }
    
    func show(_ show: Bool) {
        isHidden = !show
    }
    
    var maxLeading: CGFloat {
        return sliderRangeGuide.layoutFrame.maxX
    }
    
    var minLeading: CGFloat {
        return sliderRangeGuide.layoutFrame.minX
    }
    
    func updateProgress(percent: CGFloat) {
        leadingConstraint.constant = sliderRangeGuide.layoutFrame.minX + (sliderRangeGuide.layoutFrame.width)*CGFloat(percent)
    }
}

