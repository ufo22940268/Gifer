//
//  OverlayComponent.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

enum OverlayComponentCorner: CaseIterable {
    case delete, scale, copy, edit
    
    var icon: UIImage {
        switch self {
        case .delete:
            return #imageLiteral(resourceName: "close-outline.png")
        case .scale:
            return #imageLiteral(resourceName: "expand-outline.png")
        case .copy:
            return #imageLiteral(resourceName: "copy-outline.png")
        case .edit:
            return #imageLiteral(resourceName: "edit-outline.png")
        }
    }
}

protocol OverlayComponentDelegate: class {
    func onComponentDeleted(component: OverlayComponent)
    func onCopyComponent(component: OverlayComponent)
}

class OverlayComponent: UIView {
    
    struct Info {
        //Normalized rect
        var nRect: CGRect!
        
        var rotation = CGFloat(0)
        
        func realRect(parentSize: CGSize) -> CGRect {
            return nRect.applying(CGAffineTransform(scaleX: parentSize.width, y: parentSize.height))
        }
        
        mutating func scaleTo(_ scale: CGFloat) {
            var newRect = nRect!
            newRect.size.width = nRect.width*scale
            newRect.size.height = nRect.height*scale
            nRect = newRect
        }
        
        mutating func setRotation(_ rotation: CGFloat) {
            self.rotation = rotation
        }
        
        mutating func moveBy(_ translate: CGPoint) {
            nRect = nRect.applying(CGAffineTransform(translationX: translate.x, y: translate.y))
        }
        
        func shiftLayout() -> Info {
            var newInfo = self
            newInfo.nRect = nRect.applying(CGAffineTransform(translationX: 0.05, y: 0.05))
            return newInfo
        }
        
        func realRect(parentSize: CGSize, scale: CGFloat) -> CGRect {
            return nRect
                .applying(CGAffineTransform(scaleX: scale, y: scale))
                .applying(CGAffineTransform(scaleX: parentSize.width, y: parentSize.height))
        }
        
        init(nRect: CGRect) {
            self.nRect = nRect
        }
    }
    
    var info: Info!
    
    var isActive: Bool = true {
        didSet {
            cornerViews.forEach { $0.isHidden = !isActive }
            isUserInteractionEnabled = isActive
            setNeedsDisplay()
        }
    }
    
    var leading: NSLayoutConstraint!
    var top: NSLayoutConstraint!
    var width: NSLayoutConstraint!
    var height: NSLayoutConstraint!
    
    var cornerViews = [OverlayComponentCornerView]()
    var frameLineWidth = CGFloat(3)
    weak var delegate: OverlayComponentDelegate?
    var renderer: OverlayComponentRender!

    init(info: Info, renderer: OverlayComponentRender) {
        super.init(frame: .zero)
        useAutoLayout()
        
        self.info = info
        backgroundColor = .clear
        
        self.renderer = renderer
        addSubview(renderer)
        let margin = CGFloat(16)
        layoutMargins = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        NSLayoutConstraint.activate([
            renderer.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            renderer.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            renderer.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            renderer.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            ])

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        guard let superview = superview else { return }
        
        leading = leadingAnchor.constraint(equalTo: superview.leadingAnchor).activeAndReturn()
        top = topAnchor.constraint(equalTo: superview.topAnchor).activeAndReturn()
        width = widthAnchor.constraint(equalToConstant: 0).activeAndReturn()
        height = heightAnchor.constraint(equalToConstant: 0).activeAndReturn()
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onMove(sender:))))
        for corner in OverlayComponentCorner.allCases {
            let cornerView = OverlayComponentCornerView(corner: corner).useAutoLayout()
            addSubview(cornerView)
            cornerView.setup()
            cornerViews.append(cornerView)
            registerGesture(cornerView)
        }
    }
    
    func updateInfoPosition() {
        let rect = info.realRect(parentSize: superview!.bounds.size)
        leading.constant = rect.minX
        top.constant = rect.minY
        width.constant = rect.width
        height.constant = rect.height
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard isActive else { return }
        
        let cornerViewSize = cornerViews.first!.bounds.width
        let frameInset = (cornerViewSize - frameLineWidth)/2 + 2
        let framePath = UIBezierPath(rect: rect.insetBy(dx: frameInset, dy: frameInset))
        UIColor(named: "mainColor")?.setStroke()
        framePath.lineWidth = frameLineWidth
        framePath.stroke()
    }
    
    func registerGesture(_ view: OverlayComponentCornerView) {
        switch view.corner! {
        case .scale:
            registerScaleGesture(view: view)
        case .delete:
            view.addTarget(self, action: #selector(onDelete(sender:)), for: .touchUpInside)
        case .copy:
            view.addTarget(self, action: #selector(onCopy(sender:)), for: .touchUpInside)
        default:
            break
        }
    }
}

//Move action
extension OverlayComponent {
    @objc func onMove(sender: UIPanGestureRecognizer) {
        guard let superview = superview else {
            return
        }
        let translate = sender.translation(in: superview)
            .applying(CGAffineTransform(scaleX: 1/superview.bounds.width, y: 1/superview.bounds.height))
        info.moveBy(translate)
        updateInfoPosition()
        sender.setTranslation(translate, in: superview)
    }
}

//Scale action
extension OverlayComponent {
    func registerScaleGesture(view: OverlayComponentCornerView) {
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onScalePan(sender:))))
    }
    
    private func extractScale(_ translate: CGPoint) -> CGFloat {
        if translate.x * translate.y > 0 {
            let scale = 1 + min(translate.x, translate.y)/bounds.width
            return scale
        } else {
            return 1
        }
    }
    
    private func extractRotation(_ translate: CGPoint) -> CGFloat {
        let rect = frame
        let origin = rect.origin
        let newPoint = CGPoint(x: rect.maxX, y: rect.maxY).applying(CGAffineTransform(translationX: translate.x, y: translate.y))
        let v1 = CGVector(dx: rect.maxX - origin.x, dy: rect.maxY - origin.y)
        let v2 = CGVector(dx: newPoint.x - origin.x, dy: newPoint.y - origin.y)
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        return angle
    }
    
    @objc func onScalePan(sender: UIPanGestureRecognizer) {
        let translate = sender.translation(in: self)
        sender.setTranslation(.zero, in: self)
        let scale = extractScale(translate)
        
        let predictRect = info.realRect(parentSize: superview!.bounds.size, scale: scale)
        guard predictRect.width > 100 && predictRect.height > 100 else {
            return
        }
        
        scaleTo(scale)
        let rotation = extractRotation(translate)
        rotateBy(rotation)
    }
        
    func scaleTo(_ scale: CGFloat) {
        info.scaleTo(scale)
        updateInfoPosition()
    }
    
    private func rotateBy(_ rotation: CGFloat) {
        transform = transform.concatenating(CGAffineTransform(rotationAngle: rotation))
        info.setRotation(transform.rotation)
    }
}

//Delete action
extension OverlayComponent {
    @objc func onDelete(sender: UITapGestureRecognizer) {
        deleteComponent()
    }
    
    private func deleteComponent() {
        delegate?.onComponentDeleted(component: self)
    }
}

//Copy action
extension OverlayComponent {
    @objc func onCopy(sender: UITapGestureRecognizer) {
        copyComponent()
    }
    
    private func copyComponent() {
        delegate?.onCopyComponent(component: self)
    }
    
    func copyView() -> OverlayComponent {
        let component = OverlayComponent(info: info.shiftLayout(), renderer: renderer.copy())
        return component
    }
}
