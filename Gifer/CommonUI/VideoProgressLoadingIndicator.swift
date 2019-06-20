//
//  VideoProgressLoadingIndicator.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class VideoProgressCircle: UIView {
    
    let circleWidth = CGFloat(3)
    var progress: CGFloat = 0.2 {
        didSet {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 0.15
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = progress
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

class VideoProgressLoadingIndicator: UIVisualEffectView {

    lazy var messageView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = tintColor
        label.backgroundColor = .clear
        return label
    }()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        return view
    }()
    
    lazy var circleView: VideoProgressCircle = {
        let view = VideoProgressCircle()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 32),
            view.heightAnchor.constraint(equalToConstant: 32)])
        return view
    }()
    
    var progress: CGFloat = 0 {
        didSet {
            self.circleView.progress = self.progress.clamped(to: 0...0.95)
        }
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
        tintAdjustmentMode = .normal
        
        layer.cornerRadius = 8
        clipsToBounds = true
        effect = UIBlurEffect(style: .regular)
        tintColor = UIColor.darkGray
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)])

        stackView.addArrangedSubview(circleView)
        stackView.addArrangedSubview(messageView)
        messageView.text = "正在下载视频"
        messageView.sizeToFit()
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: stackView.widthAnchor),
            heightAnchor.constraint(equalTo: stackView.heightAnchor)
            ])
    }
}
