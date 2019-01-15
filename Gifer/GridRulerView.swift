//
//  GridRulerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

private let gridStrokeColor: UIColor = UIColor.white
private let frameWidth = CGFloat(2)
private let cornerStrokeWidth = CGFloat(4)


class RulerCornerView: UIView {
    
    private let size = CGFloat(40)
    
    enum Position: CaseIterable {
        case leftTop, rightTop, leftBottom, rightBottom

        func setupLayout(child: UIView, parent: UIView) {
            switch self {
            case .leftTop:
                NSLayoutConstraint.activate([
                    child.leftAnchor.constraint(equalTo: parent.leftAnchor),
                    child.topAnchor.constraint(equalTo: parent.topAnchor)
                    ])
            case .rightTop:
                NSLayoutConstraint.activate([
                    child.rightAnchor.constraint(equalTo: parent.rightAnchor),
                    child.topAnchor.constraint(equalTo: parent.topAnchor)
                    ])
            case .leftBottom:
                NSLayoutConstraint.activate([
                    child.leftAnchor.constraint(equalTo: parent.leftAnchor),
                    child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
                    ])
            case .rightBottom:
                NSLayoutConstraint.activate([
                    child.rightAnchor.constraint(equalTo: parent.rightAnchor),
                    child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
                    ])
            }
        }
        
        func drawCornerSymbol(in rect: CGRect) {
            let left = (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: rect.maxY))
            let top = (CGPoint(x: 0, y: 0), CGPoint(x: rect.maxX, y: 0))
            let right = (CGPoint(x: rect.maxX, y: 0), CGPoint(x: rect.maxX, y: rect.maxY))
            let bottom = (CGPoint(x: 0, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY))

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
            gridStrokeColor.setStroke()
            path.lineWidth = cornerStrokeWidth*2
            for line in lines {
                path.move(to: line.0)
                path.addLine(to: line.1)
            }
            path.stroke()
        }
    }
    
    var position: Position!
    
    init(position: Position) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        self.position = position
        backgroundColor = .clear
    }
    
    func setupLayout() {
        guard let superview = superview else {
            return
        }
        position.setupLayout(child: self, parent: superview)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        position.drawCornerSymbol(in: rect)
    }
}

class GridRulerView: UIView {
    
    override func awakeFromNib() {
        backgroundColor = UIColor.black
        
        for position in RulerCornerView.Position.allCases {
            let cornerView = RulerCornerView(position: position)
            addSubview(cornerView)
            cornerView.setupLayout()
        }
    }
    
    override func draw(_ rect: CGRect) {
        //Draw frame
        let framePath = UIBezierPath(rect: rect.insetBy(dx: cornerStrokeWidth, dy: cornerStrokeWidth))
        UIColor.white.setStroke()
//        framePath.lineWidth = frameWidth
        framePath.stroke()
    }

}
