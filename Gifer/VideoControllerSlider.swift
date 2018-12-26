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
    var sliderRangeGuide: UILayoutGuide!
    var sliderActiveRangeGuide: UILayoutGuide!
    
    fileprivate func setupGuides(trimView: VideoControllerTrim) {
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
    
    
    func setup(trimView: VideoControllerTrim) -> Void {
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
        self.layer.addSublayer(sliderLayer)                
    }
    
    func show(_ show: Bool) {
        isHidden = !show
    }
    
    @objc func onDrag(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            delegate?.onSlideVideo(state: .begin, progress: nil)
        } else if gesture.state == .changed {
            let translation = gesture.translation(in: superview)
            shiftProgress(translationX: translation.x)
            gesture.setTranslation(CGPoint.zero, in: superview)
        } else if gesture.state == .ended {
            delegate?.onSlideVideo(state: .end, progress: nil)
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        let sliderRect = layer.bounds.insetBy(dx: 0, dy: -4)
        let path = UIBezierPath(roundedRect: sliderRect, cornerRadius: layer.bounds.width/2)
        sliderLayer.path = path.cgPath
        sliderLayer.fillColor = UIColor.white.cgColor
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
        let percentage = (leadingConstraint.constant - sliderRangeGuide.layoutFrame.minX)/sliderRangeGuide.layoutFrame.width
        self.progress = duration*Double(percentage)
        print("shifted to progress: \(self.progress)")
        delegate?.onSlideVideo(state: .slide, progress: self.progress)
    }
    
    func updateProgress(progress: CMTime) {
        print("playing progress: \(progress)")
        leadingConstraint.constant = sliderRangeGuide.layoutFrame.minX +  sliderRangeGuide.layoutFrame.width*CGFloat(progress/duration)
        self.progress = progress
    }
}
