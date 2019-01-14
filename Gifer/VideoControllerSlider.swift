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
    var progress: CMTime!
    var duration: CMTime!
    
    lazy var sliderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    var leadingConstraint: NSLayoutConstraint!
    var activeLeadingConstraint: NSLayoutConstraint!
    var activeTrailingConstraint: NSLayoutConstraint!
    var sliderRangeGuide: UILayoutGuide!
    var trimView: VideoControllerTrim!
    
    fileprivate func setupGuides(trimView: VideoControllerTrim) {
        guard let superview = superview else { return }
        
        sliderRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderRangeGuide)
        activeLeadingConstraint = sliderRangeGuide.leadingAnchor.constraint(equalTo: trimView.leftTrim.trailingAnchor)
        activeLeadingConstraint.isActive = true
        activeTrailingConstraint = sliderRangeGuide.trailingAnchor.constraint(equalTo: trimView.rightTrim.leadingAnchor, constant:-VideoControllerConstants.sliderWidth)
        activeTrailingConstraint.isActive = true
    }
    
    func setup(trimView: VideoControllerTrim) -> Void {
        guard let superview = superview else { return  }
        
        setupGuides(trimView: trimView)
        self.trimView = trimView
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
        leadingConstraint = leadingAnchor.constraint(equalTo: sliderRangeGuide.leadingAnchor, constant: 0)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: VideoControllerConstants.sliderWidth),
            heightAnchor.constraint(equalTo: superview.heightAnchor, constant: 8),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            leadingConstraint
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
    
    func updateProgress(progress: CMTime) {
        let trimPosition = trimView.trimPosition
        let percentageProgress: Double = ((progress - trimPosition.leftTrim)/trimPosition.range).clamped(to: 0...1)
        print("percentageProgress: \(percentageProgress)")
        leadingConstraint.constant = (sliderRangeGuide.layoutFrame.width)*CGFloat(percentageProgress)
//        leadingConstraint.constant = CGFloat(progress/duration)*sliderRangeGuide.layoutFrame.width
        self.progress = progress
    }
}

