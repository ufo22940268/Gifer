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
    
    var delegate: SlideVideoProgressDelegate?
    var progress: CMTime!
    var duration: CMTime!
    
    lazy var sliderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    var leadingConstraint: NSLayoutConstraint!
    var activeLeadingConstraint: NSLayoutConstraint!
    var activeTrailingConstraint: NSLayoutConstraint!
    var sliderActiveRangeGuide: UILayoutGuide!
    var trimView: VideoControllerTrim!
    
    fileprivate func setupGuides(trimView: VideoControllerTrim) {
        guard let superview = superview else { return }
        
        sliderActiveRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderActiveRangeGuide)
        activeLeadingConstraint = sliderActiveRangeGuide.leadingAnchor.constraint(equalTo: trimView.leftTrim.trailingAnchor)
        activeLeadingConstraint.isActive = true
        activeTrailingConstraint = sliderActiveRangeGuide.trailingAnchor.constraint(equalTo: trimView.rightTrim.leadingAnchor, constant:-VideoControllerConstants.sliderWidth)
        activeTrailingConstraint.isActive = true
    }
    
    func setup(trimView: VideoControllerTrim) -> Void {
        guard let superview = superview else { return  }
        
        setupGuides(trimView: trimView)
        self.trimView = trimView
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
        leadingConstraint = leadingAnchor.constraint(equalTo: sliderActiveRangeGuide.leadingAnchor, constant: 0)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: VideoControllerConstants.sliderWidth),
            heightAnchor.constraint(equalTo: superview.heightAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            leadingConstraint
            ])
    }
    
    func show(_ show: Bool) {
        isHidden = !show
    }
    
    var maxLeading: CGFloat {
        return sliderActiveRangeGuide.layoutFrame.maxX
    }
    
    var minLeading: CGFloat {
        return sliderActiveRangeGuide.layoutFrame.minX
    }
    
    func updateProgress(progress: CMTime) {
        let trimPosition = trimView.trimPosition
        let percentageProgress: Double = (progress - trimPosition.leftTrim)/trimPosition.range
        leadingConstraint.constant = (sliderActiveRangeGuide.layoutFrame.width)*CGFloat(percentageProgress)
        self.progress = progress
    }
}
