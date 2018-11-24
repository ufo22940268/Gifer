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
    
    func show(_ show: Bool) {
        isHidden = !show
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
