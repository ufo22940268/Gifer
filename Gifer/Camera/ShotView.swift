//
//  ShotView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ShotView: UIView {
    
    lazy var circleView: CircleView = {
        let view = CircleView().useAutoLayout()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var ringView: RingView = {
        let view = RingView().useAutoLayout()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var progressView: ProgressView = {
        let view = ProgressView().useAutoLayout()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var shotGesture: UILongPressGestureRecognizer = {
        let ges = UILongPressGestureRecognizer(target: self, action: #selector(onShot(sender:)))
        return ges
    }()
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    var ringWidthConstraint: NSLayoutConstraint!
    var ringHeightConstraint: NSLayoutConstraint!
    var circleHeightConstraint: NSLayoutConstraint!
    var circleWidthConstraint: NSLayoutConstraint!
    
    var progress: CGFloat = 0 {
        didSet {
            progressView.progress = progress
        }
    }
    var timer: Timer?

    weak var customDelegate: ShotViewDelegate?

    override func awakeFromNib() {
        backgroundColor = .clear
        
        ringWidthConstraint = ringView.widthAnchor.constraint(equalTo: widthAnchor, constant: -20)
        ringHeightConstraint = ringView.heightAnchor.constraint(equalTo: heightAnchor, constant: -20)
        
        circleHeightConstraint = circleView.heightAnchor.constraint(equalTo: heightAnchor, constant: -40)
        circleWidthConstraint = circleView.widthAnchor.constraint(equalTo: widthAnchor, constant: -40)
        
        addSubview(ringView)
        NSLayoutConstraint.activate([
            ringWidthConstraint,
            ringHeightConstraint,
            ringView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])

        addSubview(circleView)
        NSLayoutConstraint.activate([
            circleWidthConstraint,
            circleHeightConstraint,
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        
        addSubview(progressView)
        progressView.useSameSizeAsParent()
        
        addGestureRecognizer(shotGesture)
        
        progress = 0
    }
    
    
    func startRecording() {
        customDelegate?.onStartRecordingByUser()
        
        if let timer = timer {
            timer.invalidate()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
            self.progress = min(self.progress + 0.02, 1)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stopRecording() {
        customDelegate?.onStopRecordingByUser()
        timer?.invalidate()
    }
    
    func resetRecording() {
        timer?.invalidate()
        progressView.setProgressWithoutAnimation(0)
    }
        
    @objc func onShot(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.circleWidthConstraint.constant = -60
                self.circleHeightConstraint.constant = -60
                self.ringWidthConstraint.constant = 0
                self.ringHeightConstraint.constant = 0
                self.progressView.isActive = true
                self.layoutIfNeeded()
            }, completion: nil)
            startRecording()
        case .ended:
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.circleWidthConstraint.constant = -40
                self.circleHeightConstraint.constant = -40
                self.ringWidthConstraint.constant = -20
                self.ringHeightConstraint.constant = -20
                self.progressView.isActive = false
                self.layoutIfNeeded()
            }, completion: nil)
            stopRecording()
        default:
            break
        }
    }
    
    class CircleView: UIView {
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.setFill()
            path.fill()
        }
    }
    
    class RingView: UIView {
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.withAlphaComponent(0.5).setFill()
            path.fill()
        }
    }
    
    class ProgressView: UIView {
        
        var progress: CGFloat = 0 {
            didSet {
                ringLayer.strokeStart = 0
                ringLayer.strokeEnd = progress
            }
        }
        
        let ringWidth = CGFloat(10)
        
        var isActive: Bool? {
            didSet {
                guard let isActive = isActive else { return }
                if isActive {
                    transform = CGAffineTransform(rotationAngle: -.pi/2)
                } else {
                    transform = CGAffineTransform(scaleX: (bounds.width - 20)/bounds.width, y: (bounds.height - 20)/bounds.height).rotated(by: -.pi/2)
                }
            }
        }
        
        lazy var ringLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.strokeColor = #colorLiteral(red: 0, green: 0.5603182912, blue: 0, alpha: 1).cgColor
            layer.lineWidth = 10
            layer.backgroundColor = UIColor.clear.cgColor
            let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)).insetBy(dx: ringWidth/2, dy: ringWidth/2))
            layer.path = path.cgPath
            layer.fillColor = UIColor.clear.cgColor
            return layer
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(ringLayer)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            if isActive == nil {
                isActive = false
            }
        }
        
        func setProgressWithoutAnimation(_ progress: CGFloat) {
            // FIXME: Can't disable layer action.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.progress = 0
            CATransaction.commit()
        }
    }
}

protocol ShotViewDelegate: class {
    func onStartRecordingByUser()
    func onStopRecordingByUser()
}
