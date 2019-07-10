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
let gridRulerTouchEdgeWidth = CGFloat(32)
let gridRulerCornerWidth = CGFloat(32)

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
        backgroundColor = .clear
        
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
    
    var scrollView: UIScrollView!
    var isGridChanged = false
    
    init(scrollView: UIScrollView) {
        super.init(frame: CGRect.zero)
        self.scrollView = scrollView
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The real constraints applyed to view.
    var customConstraints: CommonConstraints!
    
    /// Used to test if the constraints is abount to change is valid
    var guideConstraints: CommonConstraints!
    var guideLayout: UILayoutGuide!
    
    var frameView: GridFrameView!
    weak var delegate: GridRulerViewDelegate?

    func setup() {
        
        let findConstraint = {(identifier: String) -> NSLayoutConstraint in
            return [self.constraints, self.superview!.constraints].flatMap { $0 }.first(where: { (constraint) -> Bool in
                return constraint.identifier == identifier
            })!
        }
        
        customConstraints = CommonConstraints(centerX: findConstraint("centerX"), centerY: findConstraint("centerY"), width: findConstraint("width"), height: findConstraint("height"))
        
        layoutMargins = UIEdgeInsets(top: gridRulerCornerStrokeWidth, left: gridRulerCornerStrokeWidth, bottom: gridRulerCornerStrokeWidth, right: gridRulerCornerStrokeWidth)
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
    
    func hitBorder(point: CGPoint) -> Bool {
        let touchEdgeWidth = gridRulerTouchEdgeWidth
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
        
        return hit
    }
    
    func buildGuideConstraints(videoFrame: CGRect) {
        guard let superview = superview else { fatalError() }
        let guide = UILayoutGuide()
        superview.addLayoutGuide(guide)
        let constraints = CommonConstraints(centerX: guide.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                                            centerY: guide.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
                                            width: guide.widthAnchor.constraint(equalToConstant: videoFrame.width),
                                            height: guide.heightAnchor.constraint(equalToConstant: videoFrame.height))
        constraints.activeAll()
        guideConstraints = constraints
        guideLayout = guide
    }
    
    func setupVideo(frame videoFrame: CGRect) {
        buildGuideConstraints(videoFrame: videoFrame)
                        
        customConstraints.width.constant = videoFrame.width
        customConstraints.height.constant = videoFrame.height
        subviews.forEach { (child) in
            child.setNeedsDisplay()
        }
        frameView.divider.setNeedsDisplay()                
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
    
    func resizeTo(rect: CGRect) {
        customConstraints.width.constant = rect.width
        customConstraints.height.constant = rect.height
        guideConstraints.copy(from: customConstraints)
    }
    
    private func almostTheSame(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
        let tolleratableDiffer = CGFloat(0.5)
        return (abs(rect1.origin.x - rect2.origin.x) < tolleratableDiffer && abs(rect1.origin.y - rect2.origin.y) < tolleratableDiffer && abs(rect1.width - rect2.width) < tolleratableDiffer && abs(rect1.height - rect2.height) < tolleratableDiffer)

    }
    
    func isGuideLayoutValid() -> Bool {
        let guideFrame = guideLayout.layoutFrame
        let minimunSize = CGFloat(100)
        
        var zoomScale = scrollView.zoomScale
        zoomScale = zoomScale*max(bounds.width/guideFrame.width, bounds.height/guideFrame.height)
        
        let insideContainer = almostTheSame(guideFrame.intersection(superview!.bounds), guideFrame)
        let largeEnough = guideFrame.width > minimunSize && guideFrame.height > minimunSize
        let valid = insideContainer && largeEnough
        return valid
    }
    
    func syncConstraintsToGuide() {
        guideConstraints.copy(from: customConstraints)
    }
    
    func updateLayout(width: CGFloat, height: CGFloat, resetCenter: Bool = true) {
        customConstraints.width.constant = width
        customConstraints.height.constant = height
        if resetCenter {
            customConstraints.centerX.constant = 0
            customConstraints.centerY.constant = 0
        }
        
        syncConstraintsToGuide()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let touchEdgeWidth = gridRulerTouchEdgeWidth
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
}
