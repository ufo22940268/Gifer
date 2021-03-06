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
            DispatchQueue.main.async {                
                let p = 0.3 + self.progress*0.7
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.duration = 0.15
                animation.fromValue = self.progressLayer.strokeEnd
                animation.toValue = p
                animation.delegate = self
                self.progressLayer.add(animation, forKey: "strokeEnd")
                self.progressLayer.strokeEnd = p
            }
        }
    }
    
    weak var customDelegate: VideoProgressCircleDelegate?
    
    lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .clear
        layer.addSublayer(progressLayer)
        transform = CGAffineTransform(rotationAngle: -.pi/2)
    }
    
    func createProgressPath() -> CGPath {
        let radius: CGFloat = (bounds.width/2 - circleWidth)/2
        let rect = CGRect(origin: CGPoint(x: bounds.center.x - radius, y: bounds.center.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let progressPath = UIBezierPath(ovalIn: rect)
        return progressPath.cgPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = progress
        let radius: CGFloat = bounds.width/2 - circleWidth
        progressLayer.lineWidth = radius
        progressLayer.path = createProgressPath()
        setNeedsDisplay()
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
        if progress == 1 {
            customDelegate?.onStopped(self)
        }
    }
}

protocol VideoProgressCircleDelegate: class {
    func onStopped(_ circleView: VideoProgressCircle)
}
