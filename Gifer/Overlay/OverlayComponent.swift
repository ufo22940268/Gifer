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
            return #imageLiteral(resourceName: "close-outline-in-overlay.png")
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
    func onActive(component: OverlayComponent)
    func onEditComponent(component: OverlayComponent, id: ComponentId)
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
        
        mutating func change(nSize: CGSize) {
            let scaleX = nSize.width/nRect.width
            let scaleY = nSize.height/nRect.height
            nRect = nRect.scaleOnCenterPoint(scaleX: scaleX, scaleY: scaleY)
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
        
        static func predictNormalizedRect(textInfo: EditTextInfo, containerBounds: CGRect) -> CGRect {
            let boundsRect = containerBounds.inset(by: UIEdgeInsets(top: 62, left: 62, bottom: 62, right: 62))
            
            let label = UILabel()
            label.text = textInfo.text
            label.font = UIFont(name: textInfo.fontName, size: EditTextInfo.preferredTextSize)
            label.sizeToFit()
            let textSize = label.bounds.size
            let preferredRect = CGRect(origin: CGPoint(x: containerBounds.midX, y: containerBounds.midY).applying(CGAffineTransform(translationX: -textSize.width/2, y: -textSize.height/2)), size: textSize).insetBy(dx: -44, dy: -44)
            
            return preferredRect.intersection(boundsRect).applying(CGAffineTransform(scaleX: 1/containerBounds.width, y: 1/containerBounds.height))
        }
        
        
        static func predictNormalizedSize(textInfo: EditTextInfo, containerBounds: CGRect) -> CGSize {
            return Info.predictNormalizedRect(textInfo: textInfo, containerBounds: containerBounds).size
        }

        
        init(nRect: CGRect) {
            self.nRect = nRect
        }
    }
    
    var info: Info! {
        didSet {
            updateInfoPosition()
        }
    }
    var id: ComponentId!
    
    var isActive: Bool = true {
        didSet {
            cornerViews.forEach { $0.isHidden = !isActive }
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
    var render: OverlayComponentRender!

    init(info: Info, render: OverlayComponentRender) {
        super.init(frame: .zero)
        useAutoLayout()
        
        self.info = info
        backgroundColor = .clear
        
        self.render = render
        addSubview(render)
        let margin = CGFloat(24)
        layoutMargins = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        NSLayoutConstraint.activate([
            render.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            render.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            render.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            render.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            ])
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapToActive(sender:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(nSize: CGSize) {
        var newInfo = info
        newInfo?.change(nSize: nSize)
        info = newInfo
    }
    
    func setup(id: ComponentId) {
        guard let superview = superview else { return }
        
        self.id = id
        
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
    
    @objc func onTapToActive(sender: UITapGestureRecognizer) {
        delegate?.onActive(component: self)
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
        case .edit:
            view.addTarget(self, action: #selector(onEdit(sender:)), for: .touchUpInside)
        }
    }
}

//Move action
extension OverlayComponent {
    @objc func onMove(sender: UIPanGestureRecognizer) {
        guard let superview = superview, isActive else {
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
        let component = OverlayComponent(info: info.shiftLayout(), render: render.copy())
        return component
    }
}

//Edit action
extension OverlayComponent {
    @objc func onEdit(sender: UITapGestureRecognizer) {
        delegate?.onEditComponent(component: self, id: id)
    }
}
