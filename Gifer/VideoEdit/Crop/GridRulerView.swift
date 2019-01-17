//
//  GridRulerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

let gridRulerStrokeColor: UIColor = UIColor.white
let gridRulerFrameWidth = CGFloat(2)
let gridRulerCornerStrokeWidth = CGFloat(4)
let gridRulerTouchEdgeWidth = CGFloat(24)

class GridFrameDivider: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        gridRulerStrokeColor.setStroke()

        var lines = [(CGPoint, CGPoint)]()
        lines.append((CGPoint(x: 0, y: rect.height/3), CGPoint(x: rect.width, y: rect.height/3)))
        lines.append((CGPoint(x: 0, y: rect.height*2/3), CGPoint(x: rect.width, y: rect.height*2/3)))
        lines.append((CGPoint(x: rect.width/3, y: 0), CGPoint(x: rect.width/3, y: rect.height)))
        lines.append((CGPoint(x: rect.width*2/3, y: 0), CGPoint(x: rect.width*2/3, y: rect.height)))
        for line in lines {
            path.move(to: line.0)
            path.addLine(to: line.1)
        }
        path.stroke()
    }
}

class GridFrameView: UIView {

    var showGrid = false {
        didSet {
            UIView.transition(with: divider, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.divider.isHidden = !self.showGrid
            }, completion: nil)
        }
    }
    
    var divider: GridFrameDivider!

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = gridRulerStrokeColor.cgColor
        layer.borderWidth = gridRulerFrameWidth
        showGrid = true
        
        divider = GridFrameDivider()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isHidden = true
        addSubview(divider)
        NSLayoutConstraint.activate([
            divider.leftAnchor.constraint(equalTo: leftAnchor),
            divider.rightAnchor.constraint(equalTo: rightAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol GridRulerViewDelegate: class {
    func onDragFinished()
}

class GridRulerView: UIView {
    
    struct Constraints {
        var centerX: NSLayoutConstraint
        var centerY: NSLayoutConstraint
        var width: NSLayoutConstraint
        var height: NSLayoutConstraint
    }
    
    var customConstraints: Constraints!
    var frameView: GridFrameView!
    weak var delegate: GridRulerViewDelegate?

    func setup() {
        
        let findConstraint = {(identifier: String) -> NSLayoutConstraint in
            return [self.constraints, self.superview!.constraints].flatMap { $0 }.first(where: { (constraint) -> Bool in
                return constraint.identifier == identifier
            })!
        }
        
        customConstraints = Constraints(centerX: findConstraint("centerX"), centerY: findConstraint("centerY"), width: findConstraint("width"), height: findConstraint("height"))
        
        frameView = GridFrameView()
        addSubview(frameView)
        
        var corners = [GridRulerCornerPosition: GridRulerCornerView]()
        for position in GridRulerCornerPosition.allCases {
            let cornerView = GridRulerCornerView(position: position, parentConstraints: customConstraints)
            addSubview(cornerView)
            cornerView.setupLayout()
            cornerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))
            
            corners[position] = cornerView
            
            if position == .leftTop {
                NSLayoutConstraint.activate([
                    frameView.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: gridRulerCornerStrokeWidth),
                    frameView.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: gridRulerCornerStrokeWidth)
                    ])
            } else if position == .rightBottom {
                NSLayoutConstraint.activate([
                    frameView.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -gridRulerCornerStrokeWidth),
                    frameView.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor, constant: -gridRulerCornerStrokeWidth)])
            }
        }
        
        for position in GridRulerEdgePosition.allCases {
            let edgeView = GridRulerEdgeView(position: position)
            addSubview(edgeView)
            edgeView.setupLayout(with: corners)
            edgeView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(_:))))
        }
    }
    
    @objc func onPan(_ sender: UIPanGestureRecognizer) {
        guard let controller = sender.view as? GridRulerConstroller else {
            return
        }
        
        if sender.state == .began {
            frameView.showGrid = true
        } else if sender.state == .ended {
            frameView.showGrid = false
            delegate?.onDragFinished()
        } else {
            let point = sender.translation(in: self)
            let position = controller.controllerPosition
            position.adjustFrame(parentConstraints: customConstraints, translate: point)
        }
        sender.setTranslation(CGPoint.zero, in: self)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let touchEdgeWidth = CGFloat(24)
        let size = bounds.size
        let edges = [
            CGRect(origin: CGPoint.zero, size: CGSize(width: size.width, height: touchEdgeWidth)),
            CGRect(origin: CGPoint.zero, size: CGSize(width: touchEdgeWidth, height: size.height)),
            CGRect(origin: CGPoint(x: 0, y: size.height - touchEdgeWidth), size: CGSize(width: size.width, height: touchEdgeWidth)),
            CGRect(origin: CGPoint(x: size.width - touchEdgeWidth, y: 0), size: CGSize(width: touchEdgeWidth, height: size.height))
        ]
        
        let hit = edges.contains { (rect) -> Bool in
            rect.contains(point)
        }
        
        return hit ? super.hitTest(point, with: event) : nil
    }
    
    private func makeAspectFit(_ inner: CGRect, in outer: CGRect) -> CGRect {
        var newSize:CGSize
        if inner.size.width/inner.size.height > outer.size.width/outer.size.height {
            let r = outer.size.width/inner.size.width
            newSize = inner.size.applying(CGAffineTransform(scaleX: r, y: r))
            return CGRect(origin: CGPoint(x: 0, y: (outer.size.height - newSize.height)/2), size: newSize)
        } else {
            let r = outer.size.height/inner.size.height
            newSize = inner.size.applying(CGAffineTransform(scaleX: r, y: r))
            return CGRect(origin: CGPoint(x: (outer.size.width - newSize.width)/2, y: 0), size: newSize)
        }
    }
    
    func restoreFrame(in containerBounds: CGRect) {
        let rect = makeAspectFit(self.bounds, in: containerBounds)
        customConstraints.width.constant = rect.width - containerBounds.width
        customConstraints.height.constant = rect.height - containerBounds.height
        customConstraints.centerX.constant = 0
        customConstraints.centerY.constant = 0
    }
}
