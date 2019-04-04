//
//  OverlayComponentCornerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class OverlayComponentCornerView: UIButton {
    var corner: OverlayComponentCorner!
    
    let circleSize = CGFloat(24)
    var imageSize: CGFloat {
        return circleSize - 8
    }
    let cornerSize = CGFloat(44)
    init(corner: OverlayComponentCorner) {
        super.init(frame: .zero)
        self.corner = corner
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: cornerSize),
            heightAnchor.constraint(equalToConstant: cornerSize),
            ])
        tintColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let path = UIBezierPath(arcCenter: rect.center, radius: circleSize/2, startAngle: 0, endAngle: .pi*2, clockwise: true)
        UIColor.main.setFill()
        path.fill()
    }
    
    func setup() {
        guard let superview = superview else { return }
        
        setImage(corner.icon, for: .normal)
        let inset = CGFloat(16)
        imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        switch corner! {
        case .delete:
            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                topAnchor.constraint(equalTo: superview.topAnchor)
                ])
        case .scale:
            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                bottomAnchor.constraint(equalTo: superview.bottomAnchor)
                ])
        case .copy:
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                bottomAnchor.constraint(equalTo: superview.bottomAnchor)
                ])
        case .edit:
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                topAnchor.constraint(equalTo: superview.topAnchor)
                ])
        }
    }
}
