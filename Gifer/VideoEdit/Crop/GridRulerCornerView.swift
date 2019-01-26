//
//  GridRulerCornerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/17.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

enum GridRulerCornerPosition: CaseIterable, GridRulerControllerPosition {
    
    case leftTop, rightTop, leftBottom, rightBottom
    
    func setupLayout(child: UIView, parent: UIView) {
        switch self {
        case .leftTop:
            NSLayoutConstraint.activate([
                child.leftAnchor.constraint(equalTo: parent.layoutMarginsGuide.leftAnchor),
                child.topAnchor.constraint(equalTo: parent.layoutMarginsGuide.topAnchor)
                ])
        case .rightTop:
            NSLayoutConstraint.activate([
                child.rightAnchor.constraint(equalTo: parent.layoutMarginsGuide.rightAnchor),
                child.topAnchor.constraint(equalTo: parent.layoutMarginsGuide.topAnchor)
                ])
        case .leftBottom:
            NSLayoutConstraint.activate([
                child.leftAnchor.constraint(equalTo: parent.layoutMarginsGuide.leftAnchor),
                child.bottomAnchor.constraint(equalTo: parent.layoutMarginsGuide.bottomAnchor)
                ])
        case .rightBottom:
            NSLayoutConstraint.activate([
                child.rightAnchor.constraint(equalTo: parent.layoutMarginsGuide.rightAnchor),
                child.bottomAnchor.constraint(equalTo: parent.layoutMarginsGuide.bottomAnchor)
                ])
        }
    }
    
    func drawCornerSymbol(in rect: CGRect) {
        let halfStrokeWidth = gridRulerCornerStrokeWidth/2
        let left = (CGPoint(x: halfStrokeWidth, y: 0), CGPoint(x: halfStrokeWidth, y: rect.maxY))
        let top = (CGPoint(x: 0, y: halfStrokeWidth), CGPoint(x: rect.maxX, y: halfStrokeWidth))
        let right = (CGPoint(x: rect.maxX - halfStrokeWidth, y: 0), CGPoint(x: rect.maxX - halfStrokeWidth, y: rect.maxY))
        let bottom = (CGPoint(x: 0, y: rect.maxY - halfStrokeWidth), CGPoint(x: rect.maxX, y: rect.maxY - halfStrokeWidth))
        
        var lines = [(CGPoint, CGPoint)]()
        switch self {
        case .leftTop:
            lines.append(left)
            lines.append(top)
        case .rightTop:
            lines.append(top)
            lines.append(right)
        case .leftBottom:
            lines.append(left)
            lines.append(bottom)
        case .rightBottom:
            lines.append(right)
            lines.append(bottom)
        }
        
        let path = UIBezierPath()
        gridRulerStrokeColor.setStroke()
        path.lineWidth = gridRulerCornerStrokeWidth
        for line in lines {
            path.move(to: line.0)
            path.addLine(to: line.1)
        }
        path.stroke()
    }
    
    func isValidTransition(_ point: CGPoint) -> Bool {
        return true
    }
    
    private func roundTranslation(_ value: CGFloat) -> CGFloat {
        let v = Int(value*10000)
        return CGFloat(v - v%2)/10000
    }
    
    func adjustFrame(parentConstraints: CommonConstraints, translate: CGPoint) {
        
        let translate = CGPoint(x: roundTranslation(translate.x), y: roundTranslation(translate.y))
        
        parentConstraints.centerX.constant = parentConstraints.centerX.constant + translate.x/2
        parentConstraints.centerY.constant = parentConstraints.centerY.constant + translate.y/2
        var widthVector: CGFloat
        var heightVector: CGFloat
        switch self {
        case .leftTop:
            widthVector = -1
            heightVector = -1
        case .rightTop:
            widthVector = 1
            heightVector = -1
        case .leftBottom:
            widthVector = -1
            heightVector = 1
        case .rightBottom:
            widthVector = 1
            heightVector = 1
        }
        
        parentConstraints.width.constant = parentConstraints.width.constant + widthVector*translate.x
        parentConstraints.height.constant = parentConstraints.height.constant + heightVector*translate.y
    }
}

class GridRulerCornerView: UIView, GridRulerConstroller {
    
    var controllerPosition: GridRulerControllerPosition {
        return position as GridRulerControllerPosition
    }
    
    var position: GridRulerCornerPosition!
    var parentConstraints: CommonConstraints!
    init(position: GridRulerCornerPosition, parentConstraints: CommonConstraints) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        self.position = position
        backgroundColor = .clear
        
        self.parentConstraints = parentConstraints
    }
    
    func setupLayout() {
        guard let superview = superview else {
            return
        }
        position.setupLayout(child: self, parent: superview)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: gridRulerTouchEdgeWidth),
            heightAnchor.constraint(equalToConstant: gridRulerTouchEdgeWidth)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        position.drawCornerSymbol(in: rect)
    }
}
