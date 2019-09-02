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
        return RingView().useAutoLayout()
    }()
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    override func awakeFromNib() {
        backgroundColor = .clear
        
        addSubview(ringView)
        NSLayoutConstraint.activate([
            ringView.widthAnchor.constraint(equalTo: widthAnchor, constant: -20),
            ringView.heightAnchor.constraint(equalTo: heightAnchor, constant: -20),
            ringView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])

        addSubview(circleView)
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalTo: widthAnchor, constant: -40),
            circleView.heightAnchor.constraint(equalTo: heightAnchor, constant: -40),
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
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
}
