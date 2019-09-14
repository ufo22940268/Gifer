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

class TrimButton: UIView {
    
    enum Direction {
        case left, right
    }
    
    var backgroundLayer: CALayer!
    fileprivate var iconLayer: CAShapeLayer!
    var direction: Direction!
    var shouldEnlargeTouchArea = false
    
    init(direction: Direction) {
        super.init(frame: CGRect.zero)
        self.direction = direction
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundLayer = CAShapeLayer()
        if case .left = direction {
            backgroundLayer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        } else {
            backgroundLayer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
        backgroundLayer.cornerRadius = 4
        layer.addSublayer(backgroundLayer)
        
        iconLayer = CAShapeLayer()
        layer.addSublayer(iconLayer)
        iconLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        iconLayer.fillColor = UIColor.white.cgColor
    }
    
    override func tintColorDidChange() {
        superview?.tintColorDidChange()
        backgroundLayer.backgroundColor = tintColor.cgColor
        backgroundLayer.removeAllAnimations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var bounds: CGRect {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundLayer.frame = bounds
            iconLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            let lineHeight = bounds.height*2/3
            let lineSize = CGSize(width: 2, height: lineHeight)
            let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -lineSize.width/2, y: -lineSize.height/2), size: lineSize), cornerRadius: lineSize.width/2)
            iconLayer.path = path.cgPath
            CATransaction.commit()
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea: CGRect!
        
        let innerSideInset: CGFloat = shouldEnlargeTouchArea ? -20 : 0
        if direction == .left {
            newArea = bounds.inset(by: UIEdgeInsets(top: 0, left: -20, bottom: 0, right: innerSideInset))
        } else {
            newArea = bounds.inset(by: UIEdgeInsets(top: 0, left: innerSideInset, bottom: 0, right: -20))
        }
        return newArea.contains(point)
    }
}

let videoTimeScale = CMTimeScale(600)

class ControllerTrim: UIControl {
    
    enum Status {
        case initial, highlight
    }
    
    enum Side {
        case left, right
    }
    
    weak var slider: VideoControllerSlider?
    var changeBackgroundWhenNeeded: Bool {
        return true
    }
    
    var status: Status!
    
    var leftTrimLeadingConstraint: NSLayoutConstraint!
    var rightTrimTrailingConstraint: NSLayoutConstraint!
    let minimunGapBetweenLeftTrimAndRightTrim = CGFloat(40)
    
    var topLine: UIView!
    var bottomLine: UIView!
    
    /// Should be duration of whole video
    var duration: CMTime!
    
    /// The duration in visible gallery view. It won't exceed 20s. It's not the galleryDuration in VideoTrimPosition. It won't change after video is loaded.
    var galleryDuration: CMTime!
    
    weak var trimDelegate: VideoTrimDelegate?
    var playerItem: ImagePlayerItem?
    
    var leftTrim: TrimButton! = {
        let leftTrim = TrimButton(direction: .left)
        return leftTrim
    }()
    
    var rightTrim: TrimButton! = {
        let rightTrim = TrimButton(direction: .right)
        return rightTrim
    }()
    
    var faderBackgroundColor: UIColor {
        return UIColor(white: 0.7, alpha: 0.4)
    }
    
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
    
    static let defaultMainColor = UIColor(named: "yellowColor")!
    static let wechatMainColor = UIColor(named: "wechatColor")!
    
    private var sliderThresholdGuide: UILayoutGuide!
    
    /// Range from leading of left trim to trailing of right trim.
    var sliderRangeGuide: UILayoutGuide!
    
    var innerFrame: CGRect {
        return sliderRangeGuide.layoutFrame
    }
    
    var outerFrame: CGRect {
        return bounds
    }
    
    var originTintColor: UIColor?
    var darkTintColor: UIColor?
    
    enum Mode {
        case wechat
        case normal
    }
    
    var mode: Mode = .normal
    var galleryView: UIView!

    func setup(galleryView: UIView, hasAppendButton: Bool = false) {
        guard let superview = superview else {
            return
        }
        
        self.galleryView = galleryView
        
        isOpaque = false
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: hasAppendButton ? -40 : 0),
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
        addSubview(topLine)
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.heightAnchor.constraint(equalToConstant: VideoControllerConstants.topAndBottomInset),
            topLine.leadingAnchor.constraint(equalTo: leftTrim.trailingAnchor),
            topLine.trailingAnchor.constraint(equalTo: rightTrim.leadingAnchor)])
        
        bottomLine = UIView()
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: VideoControllerConstants.topAndBottomInset),
            bottomLine.leadingAnchor.constraint(equalTo: leftTrim.trailingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: rightTrim.leadingAnchor)])
        
        //Faders
        addSubview(leftFader)
        NSLayoutConstraint.activate([
            leftFader.leadingAnchor.constraint(equalTo: leadingAnchor, constant: VideoControllerConstants.trimWidth).with(priority: .defaultLow),
            leftFader.topAnchor.constraint(equalTo: topAnchor),
            leftFader.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftFader.trailingAnchor.constraint(equalTo: leftTrim.leadingAnchor)
            ])
        
        addSubview(rightFader)
        NSLayoutConstraint.activate([
            rightFader.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -VideoControllerConstants.trimWidth).with(priority: .defaultLow),
            rightFader.topAnchor.constraint(equalTo: topAnchor),
            rightFader.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightFader.leadingAnchor.constraint(equalTo: rightTrim.trailingAnchor)
            ])
        
        status = .highlight
        
        sliderThresholdGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderThresholdGuide)
        sliderThresholdGuide.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        sliderThresholdGuide.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        sliderRangeGuide = UILayoutGuide()
        superview.addLayoutGuide(sliderRangeGuide)
        let activeLeadingConstraint = sliderRangeGuide.leadingAnchor.constraint(equalTo: leftTrim.leadingAnchor)
        activeLeadingConstraint.isActive = true
        let activeTrailingConstraint = sliderRangeGuide.trailingAnchor.constraint(equalTo: rightTrim.trailingAnchor)
        activeTrailingConstraint.isActive = true
        
        tintColor = originTintColor
        topLine.backgroundColor = tintColor
        bottomLine.backgroundColor = tintColor        
        
        bringSubviewToFront(leftTrim)
        bringSubviewToFront(rightTrim)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard bounds.width > 150 else { return true }
        let validRect = [leftTrim.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)), rightTrim.frame.inset(by: UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0))]
        return validRect.contains { $0.contains(point) }
    }
    
    func onVideoReady() {
        updateMainColor(duration: CMTimeMultiply(Wechat.maxShareDuration.toTime(), multiplier: 2), taptic: false)
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        guard let topLine = topLine, let bottomLine = bottomLine else { return }
        topLine.backgroundColor = tintColor
        bottomLine.backgroundColor = tintColor
    }
    
    override func layoutSubviews() {
        let enlarge = innerFrame.width > 150
        leftTrim.shouldEnlargeTouchArea = enlarge
        rightTrim.shouldEnlargeTouchArea = enlarge
    }
    
    func updateMainColor(duration: CMTime? = nil, taptic: Bool = false) {
        _ = duration ?? trimPosition.galleryDuration
        
        let mode: Mode!
        if let playerItem = playerItem, changeBackgroundWhenNeeded && Wechat.canBeShared(playerItem: playerItem, trimPosition: trimPosition) {
            originTintColor = #colorLiteral(red: 0.3788883686, green: 0.8696572185, blue: 0, alpha: 1)
            darkTintColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 1)
            mode = .wechat
        } else {
            originTintColor = #colorLiteral(red: 1, green: 0.8392156863, blue: 0.0431372549, alpha: 1)
            darkTintColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
            mode = .normal
        }
        
        if taptic && mode != self.mode && mode == .wechat {
            UIDevice.current.taptic(level: 1)
        }
        self.mode = mode
        
        tintColor = originTintColor
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
        
        updatePressedState(by: recognizer.state)
        trimDelegate?.onTrimChangedByTrimer(trimPosition: trimPosition, state: getTrimState(from: recognizer), side: .left)
    }
    
    private func getTrimState(from gesture: UIPanGestureRecognizer) -> VideoTrimState {
        switch gesture.state {
        case .began:
            return .started
        case .ended:
            return .finished(false)
        default:
            return .moving(seekToSlider: false)
        }
    }
    
    @objc func onRightTrimDragged(recognizer: UIPanGestureRecognizer) {
        let translate = recognizer.translation(in: self)
        let minRightTrailing = -(bounds.width - minimunGapBetweenLeftTrimAndRightTrim - leftTrimLeadingConstraint.constant)
        let newConstant = (rightTrimTrailingConstraint.constant + translate.x).clamped(to: minRightTrailing...0)
        rightTrimTrailingConstraint.constant = newConstant
        recognizer.setTranslation(CGPoint.zero, in: self)
        updatePressedState(by: recognizer.state)
        
        trimDelegate?.onTrimChangedByTrimer(trimPosition: trimPosition, state: getTrimState(from: recognizer), side: .right)
    }
    
    private func updatePressedState(by state: UIGestureRecognizer.State) {
        switch state {
        case .ended:
            tintColor = originTintColor
        default:
            tintColor = darkTintColor
        }
    }
    
    var trimRange: CGFloat {
        return bounds.width - VideoControllerConstants.trimWidth*2
    }
    
    var trimPosition: VideoTrimPosition {
        if galleryView.bounds.size.width == 0 {
            return VideoTrimPosition(leftTrim: CMTime.zero, rightTrim: galleryDuration)
        }
        
        let leftPercent = leftTrim.convert(CGPoint(x: leftTrim.bounds.maxX, y: 0), to: galleryView).x/galleryView.bounds.width
        let rightPercent = rightTrim.convert(CGPoint(x: rightTrim.bounds.minX, y: 0), to: galleryView).x/galleryView.bounds.width
        let leftTrim = CMTimeMultiplyByFloat64(duration, multiplier: Float64(leftPercent))
        let rightTrim = CMTimeMultiplyByFloat64(duration, multiplier: Float64(rightPercent))
        return VideoTrimPosition(leftTrim: leftTrim, rightTrim: rightTrim)
    }
    
    @discardableResult
    func move(by deltaX: CGFloat) -> Bool {
        guard leftTrimLeadingConstraint.constant + deltaX >= 0 && rightTrimTrailingConstraint.constant + deltaX <= 0 else { return false }
        leftTrimLeadingConstraint.constant = leftTrimLeadingConstraint.constant + deltaX
        rightTrimTrailingConstraint.constant = rightTrimTrailingConstraint.constant + deltaX
        return true
    }
    
    /// Caused by external action. Such as high resolution button is tapped.
    func updateRange(trimPosition: VideoTrimPosition) {
        leftTrimLeadingConstraint.constant = sliderThresholdGuide.layoutFrame.width*CGFloat(trimPosition.leftTrim.seconds/duration.seconds)
        rightTrimTrailingConstraint.constant = -sliderThresholdGuide.layoutFrame.width*CGFloat(1 - trimPosition.rightTrim.seconds/duration.seconds)
        updateMainColor(duration: trimPosition.galleryDuration)
    }
}

func percentageToProgress(_ percentage: CGFloat, inDuration duration: CMTime) -> CMTime {
    return CMTimeMultiplyByFloat64(duration, multiplier: Float64(percentage))
}
