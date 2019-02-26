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

class LargeImageView: UIImageView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let increaseWidth = CGFloat(30)
        let newArea = CGRect(origin: bounds.origin.applying(CGAffineTransform(translationX: -increaseWidth/2, y: 0)), size: CGSize(width: bounds.width + increaseWidth, height: bounds.height))
        return newArea.contains(point)
    }
}

let videoTimeScale = CMTimeScale(600)

class VideoControllerTrim: UIControl {
    
    enum Status {
        case initial, highlight

        func applyTheme(to view: VideoControllerTrim) {
            var frameColor: UIColor
            var arrowColor: UIColor
            switch self {
            case .initial:
                frameColor = UIColor.black
                arrowColor = UIColor.white
            case .highlight:
                frameColor = UIColor(named: "mainColor")!
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
    let minimunGapBetweenLeftTrimAndRightTrim = CGFloat(80)
    
    var topLine: UIView!
    var bottomLine: UIView!
    var duration: CMTime!
    var galleryDuration: CMTime!
    
    weak var trimDelegate: VideoTrimDelegate?
    
    var leftTrim: UIImageView! = {
        let leftTrim = LargeImageView()
        leftTrim.translatesAutoresizingMaskIntoConstraints = false
        leftTrim.backgroundColor = UIColor(named: "mainColor")
        leftTrim.image = #imageLiteral(resourceName: "arrow-ios-back-outline.png")
        leftTrim.contentMode = .center
        return leftTrim
    }()
    
    var rightTrim: UIImageView! = {
        let rightTrim = LargeImageView()
        rightTrim.translatesAutoresizingMaskIntoConstraints = false
        rightTrim.backgroundColor = UIColor(named: "mainColor")
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
        return UIColor(named: "mainColor")!
    }
    
    var galleryView: UIView!
    private var sliderThresholdGuide: UILayoutGuide!
    private var sliderRangeGuide: UILayoutGuide!
    
    func setup(galleryView: UIView) {
        guard let superview = superview else {
            return
        }
        
        self.galleryView = galleryView
        
        
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

        status = .highlight
        
        sliderThresholdGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderThresholdGuide)
        sliderThresholdGuide.leadingAnchor.constraint(equalTo: galleryView.leadingAnchor).isActive = true
        sliderThresholdGuide.trailingAnchor.constraint(equalTo: galleryView.trailingAnchor).isActive = true
        
        sliderRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderRangeGuide)
        let activeLeadingConstraint = sliderRangeGuide.leadingAnchor.constraint(equalTo: leftTrim.leadingAnchor)
        activeLeadingConstraint.isActive = true
        let activeTrailingConstraint = sliderRangeGuide.trailingAnchor.constraint(equalTo: rightTrim.trailingAnchor)
        activeTrailingConstraint.isActive = true
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
        let newConstant = (leftTrimLeadingConstraint.constant + translate.x).clamped(to: 0...maxLeftLeading)
        leftTrimLeadingConstraint.constant = newConstant
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        trimDelegate?.onTrimChanged(position: trimPosition, state: getTrimState(from: recognizer))
    }
    
    private func getTrimState(from gesture: UIPanGestureRecognizer) -> VideoTrimState {
        switch gesture.state {
        case .began:
            return .started
        case .ended:
            return .finished(false)
        default:
            return .moving
        }
    }
    
    @objc func onRightTrimDragged(recognizer: UIPanGestureRecognizer) {        
        let translate = recognizer.translation(in: self)
        let minRightTrailing = -(bounds.width - minimunGapBetweenLeftTrimAndRightTrim - leftTrimLeadingConstraint.constant)
        let newConstant = (rightTrimTrailingConstraint.constant + translate.x).clamped(to: minRightTrailing...0)
        rightTrimTrailingConstraint.constant = newConstant
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        trimDelegate?.onTrimChanged(position: trimPosition, state: getTrimState(from: recognizer))
   }
    
    var trimRange: CGFloat {
        return bounds.width - VideoControllerConstants.trimWidth*2
    }
    
    var trimPosition: VideoTrimPosition {
        let outer = sliderThresholdGuide.layoutFrame
        let inner = sliderRangeGuide.layoutFrame
        
        let leftPercent = (inner.minX - outer.minX)/outer.width
        let leftTrim = CMTimeMultiplyByFloat64(duration, multiplier: Float64(leftPercent))
        let rightPercent = (inner.maxX - outer.minX)/outer.width
        let rightTrim = CMTimeMultiplyByFloat64(duration, multiplier: Float64(rightPercent))
        
        return VideoTrimPosition(leftTrim: leftTrim, rightTrim: rightTrim)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == leftTrim || hitView == rightTrim {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
}

func percentageToProgress(_ percentage: CGFloat, inDuration duration: CMTime) -> CMTime {
    return CMTimeMultiplyByFloat64(duration, multiplier: Float64(percentage))
}
