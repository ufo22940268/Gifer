//
//  VideoProgressCircle.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class VideoProgressCircle: UIView {
    
    let circleWidth = CGFloat(3)
    var progress: CGFloat = 0.1 {
        didSet {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 0.15
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = progress
            animation.delegate = self
            progressLayer.add(animation, forKey: "strokeEnd")
            progressLayer.strokeEnd = progress
        }
    }
    
    lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = self.tintColor.cgColor
        return layer
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .clear
        layer.addSublayer(progressLayer)
        transform = CGAffineTransform(rotationAngle: -.pi/2)
    }
    
    func createProgressPath() -> CGPath {
        let rect = bounds
        let radius: CGFloat = (rect.width - circleWidth)/2/2
        let inset = rect.width/2 - radius
        let progressPath = UIBezierPath(ovalIn: rect.insetBy(dx: inset, dy: inset))
        progressPath.lineWidth = radius
        return progressPath.cgPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = progress
        let radius: CGFloat = (bounds.width - circleWidth)/2
        progressLayer.lineWidth = radius
        progressLayer.path = createProgressPath()
    }
    
    override func tintColorDidChange() {
        progressLayer.strokeColor = tintColor.cgColor
    }
    
    override func draw(_ rect: CGRect) {
        let circleCenter: CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        let path = UIBezierPath(arcCenter: circleCenter, radius: (rect.width - circleWidth)/2, startAngle: 0, endAngle: .pi*2, clockwise: true)
        tintColor.setStroke()
        path.lineWidth = circleWidth
        path.stroke()
    }
}

extension VideoProgressCircle: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let anim = anim as? CABasicAnimation, let progress = anim.toValue as? CGFloat {
            print("progress: \(progress)")
        }
    }
}
