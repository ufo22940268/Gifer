//
//  GridRulerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

private let gridStrokeColor: UIColor = UIColor.white
private let frameWidth = CGFloat(1)
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
            let halfStrokeWidth = cornerStrokeWidth/2
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
            gridStrokeColor.setStroke()
            path.lineWidth = cornerStrokeWidth
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
        
        func adjustFrame(parentConstraints: GridRulerView.Constraints, translate: CGPoint) {
            
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
    
    
    var position: Position!
    var parentConstraints: GridRulerView.Constraints!
    
    init(position: Position, parentConstraints: GridRulerView.Constraints) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        self.position = position
        backgroundColor = .clear
        
        self.parentConstraints = parentConstraints
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(_:))))
    }
    
    
    @objc func onPan(_ sender: UIPanGestureRecognizer) {
        let point = sender.translation(in: self)
        if position.isValidTransition(point) {
            position.adjustFrame(parentConstraints: parentConstraints, translate: point)
        }
        sender.setTranslation(CGPoint.zero, in: self)
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

class GridFrameView: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = gridStrokeColor.cgColor
        layer.borderWidth = frameWidth
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class GridRulerView: UIView {
    
    struct Constraints {
        var centerX: NSLayoutConstraint
        var centerY: NSLayoutConstraint
        var width: NSLayoutConstraint
        var height: NSLayoutConstraint
    }
    
    var customConstraints: Constraints!

    override func awakeFromNib() {
        backgroundColor = UIColor.black
        
        let findConstraint = {(identifier: String) -> NSLayoutConstraint in
            return [self.constraints, self.superview!.constraints].flatMap { $0 }.first(where: { (constraint) -> Bool in
                return constraint.identifier == identifier
            })!
        }
        
        customConstraints = Constraints(centerX: findConstraint("centerX"), centerY: findConstraint("centerY"), width: findConstraint("width"), height: findConstraint("height"))
        
        let frameView = GridFrameView()
        addSubview(frameView)
        
        for position in RulerCornerView.Position.allCases {
            let cornerView = RulerCornerView(position: position, parentConstraints: customConstraints)
            addSubview(cornerView)
            cornerView.setupLayout()
            
            if position == .leftTop {
                NSLayoutConstraint.activate([
                    frameView.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: cornerStrokeWidth),
                    frameView.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: cornerStrokeWidth)
                    ])
            } else if position == .rightBottom {
                NSLayoutConstraint.activate([
                    frameView.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -cornerStrokeWidth),
                    frameView.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor, constant: -cornerStrokeWidth)])
            }
        }
        
    }
    
}
