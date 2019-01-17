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
        
        var centerXSnapshot: CGFloat = 0
        var centerYSnapshot: CGFloat = 0
        var widthSnapshot: CGFloat = 0
        var heightSnapshot: CGFloat = 0
        
        init(centerX: NSLayoutConstraint, centerY: NSLayoutConstraint, width: NSLayoutConstraint, height: NSLayoutConstraint) {
            self.centerX = centerX
            self.centerY = centerY
            self.width = width
            self.height = height
        }
        
        mutating func snapshot() {
            centerXSnapshot = centerX.constant
            centerYSnapshot = centerY.constant
            widthSnapshot = width.constant
            heightSnapshot = height.constant
        }
        
        mutating func rollback() {
            centerX.constant = centerXSnapshot
            centerY.constant = centerYSnapshot
            width.constant = widthSnapshot
            height.constant = heightSnapshot
        }
        
        mutating func copy(from constraints: Constraints) {
            centerX.constant = constraints.centerX.constant
            centerY.constant = constraints.centerY.constant
            width.constant = constraints.width.constant
            height.constant = constraints.height.constant
        }
        
        func activeAll() {
            NSLayoutConstraint.activate([centerX, centerY, width, height])
        }
    }
    
    var customConstraints: Constraints!
    var guideConstraints: Constraints!
    var guideLayout: UILayoutGuide!
    
    var frameView: GridFrameView!
    weak var delegate: GridRulerViewDelegate?

    func setup() {
        
        let findConstraint = {(identifier: String) -> NSLayoutConstraint in
            return [self.constraints, self.superview!.constraints].flatMap { $0 }.first(where: { (constraint) -> Bool in
                return constraint.identifier == identifier
            })!
        }
        
        customConstraints = Constraints(centerX: findConstraint("centerX"), centerY: findConstraint("centerY"), width: findConstraint("width"), height: findConstraint("height"))
        buildGuideConstraints()
        
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
    
    func buildGuideConstraints() {
        guard let superview = superview else { fatalError() }
        let guide = UILayoutGuide()
        superview.addLayoutGuide(guide)
        let constraints = Constraints(centerX: guide.centerXAnchor.constraint(equalTo: superview.centerXAnchor), centerY: guide.centerYAnchor.constraint(equalTo: superview.centerYAnchor), width: guide.widthAnchor.constraint(equalTo: superview.widthAnchor), height: guide.heightAnchor.constraint(equalTo: superview.heightAnchor))
        constraints.activeAll()
        guideConstraints = constraints
        guideLayout = guide
    }
    
    @objc func onPan(_ sender: UIPanGestureRecognizer) {
        guard let controller = sender.view as? GridRulerConstroller else {
            return
        }
        
        if sender.state == .began {
            frameView.showGrid = true
            guideConstraints.copy(from: customConstraints)
        } else if sender.state == .ended {
            frameView.showGrid = false
            delegate?.onDragFinished()
        } else {
            let point = sender.translation(in: self)
            let position = controller.controllerPosition
            guideConstraints.snapshot()
            position.adjustFrame(parentConstraints: guideConstraints, translate: point)
            if isGuideLayoutValid() {
                position.adjustFrame(parentConstraints: customConstraints, translate: point)
            } else {
                guideConstraints.rollback()
            }
        }
        sender.setTranslation(CGPoint.zero, in: self)
    }
    
    private func almostTheSame(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
        let tolleratableDiffer = CGFloat(0.5)
        return (abs(rect1.origin.x - rect2.origin.x) < tolleratableDiffer && abs(rect1.origin.y - rect2.origin.y) < tolleratableDiffer && abs(rect1.width - rect2.width) < tolleratableDiffer && abs(rect1.height - rect2.height) < tolleratableDiffer)

    }
    
    func isGuideLayoutValid() -> Bool {
        let guideFrame = guideLayout.layoutFrame
        let minimunSize = CGFloat(90)
        return almostTheSame(guideFrame.intersection(superview!.bounds), guideFrame) && guideFrame.width > minimunSize && guideFrame.height > minimunSize
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
    
    func makeAspectFit(in outer: CGRect) -> CGRect {
        let inner = self.bounds
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
        let rect = makeAspectFit(in: containerBounds)
        customConstraints.width.constant = rect.width - containerBounds.width
        customConstraints.height.constant = rect.height - containerBounds.height
        customConstraints.centerX.constant = 0
        customConstraints.centerY.constant = 0
    }
}
