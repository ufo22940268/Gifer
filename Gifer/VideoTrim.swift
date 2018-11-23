//
//  VideoTrim.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

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
