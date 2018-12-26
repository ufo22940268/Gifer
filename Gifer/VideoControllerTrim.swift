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

class VideoControllerTrim: UIControl {
    
    enum Status {
        case initial, changed

        func applyTheme(to view: VideoControllerTrim) {
            var frameColor: UIColor
            var arrowColor: UIColor
            switch self {
            case .initial:
                frameColor = UIColor.black
                arrowColor = UIColor.white
            case .changed:
                frameColor = UIColor.yellow
                arrowColor = UIColor.black
            }

            view.setArrowColor(arrowColor)
            view.setFrameColor(frameColor)
        }
    }
    
    var status: Status! {
        didSet {
            status.applyTheme(to:self)
        }
    }
    
    var leftTrimLeadingConstraint: NSLayoutConstraint!
    var rightTrimTrailingConstraint: NSLayoutConstraint!
    let minimunGapBetweenLeftTrimAndRightTrim = CGFloat(50)
    
    var topLine: UIView!
    var bottomLine: UIView!
    var duration: CMTime!
    
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
        
        //Faders
        addSubview(leftFader)
        NSLayoutConstraint.activate([
            leftFader.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftFader.topAnchor.constraint(equalTo: topAnchor),
            leftFader.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftFader.trailingAnchor.constraint(equalTo: leftTrim.leadingAnchor)
            ])
        
        addSubview(rightFader)
        NSLayoutConstraint.activate([
            rightFader.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightFader.topAnchor.constraint(equalTo: topAnchor),
            rightFader.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightFader.leadingAnchor.constraint(equalTo: rightTrim.trailingAnchor)
            ])

        status = .initial
    }
    
    func setFrameColor(_ color: UIColor) {
        topLine.backgroundColor = color
        bottomLine.backgroundColor = color
        leftTrim.backgroundColor = color
        rightTrim.backgroundColor = color
    }
    
    func setArrowColor(_ color: UIColor) {
        [leftTrim, rightTrim].forEach { (view) in
            view?.tintColor = color
        }
    }
    
    var maxLeftLeading: CGFloat {
        get {
            return self.bounds.width - minimunGapBetweenLeftTrimAndRightTrim - abs(rightTrimTrailingConstraint.constant)
        }
    }

    @objc func onLeftTrimDragged(recognizer: UIPanGestureRecognizer) {
        let translate = recognizer.translation(in: self)
        let newConstant = leftTrimLeadingConstraint.constant + translate.x
        leftTrimLeadingConstraint.constant = newConstant.clamped(to: 0...maxLeftLeading)
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        triggerTrimDelegate()
        status = .changed
    }
    
    @objc func onRightTrimDragged(recognizer: UIPanGestureRecognizer) {
        let translate = recognizer.translation(in: self)
        let minRightTrailing = -(bounds.width - minimunGapBetweenLeftTrimAndRightTrim - leftTrimLeadingConstraint.constant)
        let newConstant = rightTrimTrailingConstraint.constant + translate.x
        rightTrimTrailingConstraint.constant = newConstant.clamped(to: minRightTrailing...0)
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        triggerTrimDelegate()
        status = .changed
    }
    
    var trimRange: CGFloat {
        return bounds.width - VideoControllerConstants.trimWidth
    }
    
    func triggerTrimDelegate() {
        let trimPosition = VideoTrimPosition(leftTrim: percentageToProgress(leftTrimLeadingConstraint.constant/maxLeftLeading, inDuration: duration) , rightTrim: percentageToProgress((trimRange - abs(rightTrimTrailingConstraint.constant))/trimRange, inDuration: duration) )
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


func percentageToProgress(_ percentage: CGFloat, inDuration duration: CMTime) -> CMTime {
    return duration*Double(percentage)
}
