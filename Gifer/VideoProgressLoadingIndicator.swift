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
    var progress: CGFloat = 0.3 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let circleCenter: CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        let path = UIBezierPath(arcCenter: circleCenter, radius: (rect.width - circleWidth)/2, startAngle: 0, endAngle: .pi*2, clockwise: true)
        tintColor.setStroke()
        path.lineWidth = circleWidth
        path.stroke()
        
        let progressPath = UIBezierPath()
        progressPath.move(to: circleCenter)
        progressPath.addArc(withCenter: circleCenter, radius: (rect.width - circleWidth)/2, startAngle: -.pi*0.5, endAngle: -.pi*0.5 + .pi*2*progress, clockwise: true)
        tintColor.setFill()
        progressPath.fill()
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
            circleView.progress = progress
        }
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
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
