//
//  ShotView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class ShotView: UIView {
    
    lazy var circleView: CenterView = {
        let view = CenterView(mode: .video).useAutoLayout()
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
    
    lazy var shotVideoGesture: UILongPressGestureRecognizer = {
        let ges = UILongPressGestureRecognizer(target: self, action: #selector(onRecordVideo(sender:)))
        ges.minimumPressDuration = 0
        return ges
    }()
    
    lazy var shotPhotosGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(onShotPhotos(sender:)))
    }()
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    var mode: CameraMode! {
        didSet {
            if mode == .video {
                shotVideoGesture.isEnabled = true
                shotPhotosGesture.isEnabled = false
            } else {
                shotVideoGesture.isEnabled = false
                shotPhotosGesture.isEnabled = true
            }
            
            circleView.isVideoRecording = false
            circleView.mode = mode
        }
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
        
        layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
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
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalTo: layoutMarginsGuide.widthAnchor),
            progressView.heightAnchor.constraint(equalTo: layoutMarginsGuide.heightAnchor),
            progressView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
            ])

        addGestureRecognizer(shotVideoGesture)
        addGestureRecognizer(shotPhotosGesture)

        progress = 0
    }
    
    
    func startRecording() {
        customDelegate?.onStartRecordingByUser()
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.circleView.isVideoRecording = true
        }, completion: nil)
        
        if let timer = timer {
            timer.invalidate()
        }
        
        let interval = 0.1
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            self.customDelegate?.onRecording(self)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stopRecording() {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.circleView.isVideoRecording = false
        }, completion: nil)
        customDelegate?.onStopRecordingByUser()
        timer?.invalidate()
    }
    
    func resetRecording() {
        timer?.invalidate()
        progressView.setProgressWithoutAnimation(0)
    }
    
    func updateProgress(byPhotoCount photoCount: Int) {
        progress = min(CGFloat(photoCount)/CGFloat(CameraMode.maxPhotoCount), 1)
    }
    
    func updateProgress(byVideoDuration duration: CMTime) {
        progress = min(CGFloat(duration.seconds/CameraMode.maxVideoDuration.seconds), 1)
    }
    
    @objc func onShotPhotos(sender: UITapGestureRecognizer) {
        UIDevice.current.taptic(level: 1)
        UIView.animateKeyframes(withDuration: 0.2, delay: 0, options: [], animations: {
            let originTransform = self.circleView.transform
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                self.circleView.transform = self.circleView.transform.scaledBy(x: 0.9, y: 0.9)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 1, animations: {
                self.circleView.transform = originTransform
            })
        }, completion: nil)
        customDelegate?.onTakePhoto(self)
    }
        
    @objc func onRecordVideo(sender: UILongPressGestureRecognizer) {
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
    
    class CenterView: UIView {

        var isVideoRecording: Bool? {
            didSet {
                updateShape()
            }
        }
        
        var mode: CameraMode! {
            didSet {
                switch mode! {
                case .video:
                    backgroundColor = #colorLiteral(red: 0.9543388486, green: 0.197738409, blue: 0.2006814182, alpha: 1)
                case .photos:
                    backgroundColor = .white
                }
            }
        }
        
        convenience init(mode: CameraMode) {
            self.init(frame: .zero)
            self.mode = mode
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        fileprivate func updateShape() {
            switch mode! {
            case .video:
                if isVideoRecording == true {
                    layer.cornerRadius = 4
                } else {
                    layer.cornerRadius = bounds.width/2
                }
            case .photos:
                layer.cornerRadius = bounds.width/2
            }
        }
        
        override func layoutSubviews() {
            updateShape()
        }
    }
    
    class RingView: UIView {
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.withAlphaComponent(0.7).setFill()
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
                    transform = CGAffineTransform(scaleX: (bounds.width + 20)/bounds.width, y: (bounds.height + 20)/bounds.height).rotated(by: -.pi/2)
                } else {
                    transform = CGAffineTransform(rotationAngle: -.pi/2)
                }
            }
        }
        
        lazy var ringLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.strokeColor = #colorLiteral(red: 0.3533350229, green: 0.7218242288, blue: 0.3300692737, alpha: 1).cgColor
            layer.lineWidth = 10
            layer.backgroundColor = UIColor.clear.cgColor
            layer.fillColor = UIColor.clear.cgColor
            return layer
        }()

        override var bounds: CGRect {
            didSet {
                let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height)).insetBy(dx: ringWidth/2, dy: ringWidth/2))
                ringLayer.path = path.cgPath
            }
        }
        
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
    func onRecording(_ shotView: ShotView)
    func onStopRecordingByUser()
    func onTakePhoto(_ shotView: ShotView)
}
