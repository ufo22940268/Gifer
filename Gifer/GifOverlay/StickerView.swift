//
//  StickerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol StickerViewDelegate: class {
    func onStickerPanStateChanged(state: UIPanGestureRecognizer.State, sticker: StickerView)
}

extension Int {
    func degreeToRadians() -> CGFloat {
        return CGFloat(self) * .pi/180
    }
}

extension CGAffineTransform {
    var rotation: CGFloat {
        return atan2(self.b, self.a)
    }
}



class StickerView: UIView {
    
    var customConstraints: CommonConstraints!
    var guideConstraints: CommonConstraints!
    var guide: UILayoutGuide!
    weak var stickerDelegate: StickerViewDelegate?
    var imageView: UIImageView!
    
    var frameColor = UIColor.white
    var sticker: Sticker!
    var hideFrame: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    override var frame: CGRect {
        didSet {
            updateStickerFrame()
        }
    }
    
    var validBoundsForDelete: CGRect {
        let size = CGFloat(80)
        let preferredBounds = CGRect(origin: CGPoint(x: bounds.midX - size/2, y: bounds.midY - size/2), size: CGSize(width: size, height: size))
        return bounds.intersection(preferredBounds)
    }

    init(image: UIImage, sticker: Sticker) {
        self.sticker = sticker
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        layoutMargins = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
        backgroundColor = .clear
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ])
        imageView.image = image
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateStickerFrame() {
        guard let superview = superview else { return }
        sticker.frame = frame.applying(CGAffineTransform(scaleX: 1/superview.bounds.width, y: 1/superview.bounds.height))
        sticker.imageFrame = imageView.convert(imageView.bounds, to: superview).applying(CGAffineTransform(scaleX: 1/superview.bounds.width, y: 1/superview.bounds.height))
    }
    
    private func updateStickerRotation() {
        guard let superview = superview else { return }
        sticker.rotation = transform.rotation
    }
    
    func updateLayoutWhenContainerSizeChanged() {
        if var stickerFrame = sticker.frame, let containerSize = superview?.bounds.size, let superview = superview {
            stickerFrame = stickerFrame.applying(CGAffineTransform(scaleX: containerSize.width, y: containerSize.height))
            customConstraints.width.constant = stickerFrame.width
            customConstraints.height.constant = stickerFrame.height
            
            let superviewCenterPoint = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
            let stickerCenterPoint = CGPoint(x: stickerFrame.midX, y: stickerFrame.midY)
            customConstraints.centerX.constant = stickerCenterPoint.x - superviewCenterPoint.x
            customConstraints.centerY.constant = stickerCenterPoint.y - superviewCenterPoint.y
            syncToGuideConstraints()
        }
    }
    
    func syncToGuideConstraints() {
        guideConstraints.copy(from: customConstraints)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !hideFrame else { return }
        
        let frameRect: CGRect = rect.inset(by: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        let framePath = UIBezierPath(rect: frameRect)
        frameColor.setStroke()
        framePath.lineWidth = 2
        framePath.stroke()
        
        let dotPositions = [
            CGPoint(x: frameRect.minX, y: frameRect.minY),
            CGPoint(x: frameRect.maxX, y: frameRect.minY),
            CGPoint(x: frameRect.minX, y: frameRect.maxY),
            CGPoint(x: frameRect.maxX, y: frameRect.maxY)
        ]
        for position in dotPositions {
            let dotSize = CGFloat(10)
            let dotRect = CGRect(origin: position.applying(CGAffineTransform(translationX: -dotSize/2, y: -dotSize/2)), size: CGSize(width: dotSize, height: dotSize))
            frameColor.setFill()
            UIBezierPath(rect: dotRect).fill()
        }
    }
    
    func registerEditRecognizer() {
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(onPinch(sender:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:))))
        addGestureRecognizer(UIRotationGestureRecognizer(target: self, action: #selector(onRotate(sender:))))
    }
    
    @objc func onPinch(sender: UIPinchGestureRecognizer) {
        let applyChange = {(constraints: CommonConstraints) in
            constraints.width.constant = constraints.width.constant*sender.scale
            constraints.height.constant = constraints.height.constant*sender.scale
        }
        
        if sender.scale > 0 {
            guideConstraints.snapshot()
            applyChange(guideConstraints)
            if guideOverflow() && isSizeTooSmall() {
                guideConstraints.rollback()
            } else {
                applyChange(customConstraints)
            }
        }
        updateStickerFrame()
        sender.scale = 1
    }
    
    @objc func onPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        let applyChange = {(constants: CommonConstraints) in
            constants.centerX.constant = constants.centerX.constant + translation.x
            constants.centerY.constant = constants.centerY.constant + translation.y
        }
        
        guideConstraints.snapshot()
        if guideOverflow() {
            guideConstraints.rollback()
        } else {
            applyChange(customConstraints)
        }
        sender.setTranslation(CGPoint.zero, in: self)
           stickerDelegate?.onStickerPanStateChanged(state: sender.state, sticker: self)
        superview?.layoutIfNeeded()
        updateStickerFrame()
    }
    
    @objc func onRotate(sender: UIRotationGestureRecognizer) {
        transform = transform.concatenating(CGAffineTransform(rotationAngle: sender.rotation))
        sender.rotation = 0
        
        updateStickerRotation()
    }
    
    private func guideOverflow() -> Bool {
        let intersection = guide.layoutFrame.intersection(superview!.bounds)
        return !(almostEqual(intersection.width, guide.layoutFrame.width) && almostEqual(intersection.height, guide.layoutFrame.height))
    }
    
    private func isSizeTooSmall() -> Bool {
        return guide.layoutFrame.width < 50
    }
    
    private func almostEqual(_ l: CGFloat, _ r: CGFloat) -> Bool {
        return abs(l - r) < 1
    }
    
    func hoverOnTrash(_ hover: Bool) {
        if hover {
            alpha = 0.3
        } else {
            alpha = 1
        }
    }
}
