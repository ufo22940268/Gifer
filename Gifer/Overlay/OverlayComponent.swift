//
//  OverlayComponent.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/30.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

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
    
    enum `Type` {
        case text
        case sticker
    }

    struct Info {
        
        //Normalized rect
        var nRect: CGRect!
        
        var rotation = CGFloat(0)
        var type: OverlayComponent.`Type`!
        
        func realRect(parentSize: CGSize) -> CGRect {
            switch type! {
            case .text:
                return nRect.applying(CGAffineTransform(scaleX: parentSize.width, y: parentSize.height))
            case .sticker:
                return nRect.applying(CGAffineTransform(scaleX: parentSize.width, y: parentSize.height))
            }
        }
        
        /// Initialized for text component.
        ///
        /// - Parameter nRect: <#nRect description#>
        init(nRect: CGRect) {
            self.nRect = nRect
            type = .text
        }
        
        /// Inititialzed for sticker component.i
        ///
        /// - Parameters:
        ///   - stickerInfo: <#stickerInfo description#>
        ///   - containerBounds: <#containerBounds description#>
        init(stickerInfo: StickerInfo, containerBounds: CGRect) {
            self.nRect = getInitialNRect(sticker: stickerInfo, containerBounds: containerBounds)
            type = .sticker
        }
        
        mutating func scaleBy(_ scale: CGFloat, anchorCenter: Bool) {
            var newRect = nRect!
            if anchorCenter {
                newRect.origin = newRect.origin.applying(CGAffineTransform(translationX: nRect.width*(1 - scale)/2, y: nRect.height*(1 - scale)/2))        
                newRect.size.width = nRect.width*scale
                newRect.size.height = nRect.height*scale
            } else {
                newRect.size.width = nRect.width*scale
                newRect.size.height = nRect.height*scale
            }
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
        
        private func getInitialNRect(sticker: StickerInfo, containerBounds: CGRect) -> CGRect {
            let size = CGSize(width: 140, height: 140)
            let boundsRect = CGRect(origin: CGPoint(x: (containerBounds.width - size.width)/2, y: (containerBounds.height - size.height)/2), size: size)
            return boundsRect.normalizeRect(containerSize: containerBounds.size)
        }

        static func getInitialNRect(textInfo: EditTextInfo, containerBounds: CGRect) -> CGRect {
            let label = UILabel()
            label.text = textInfo.text
            label.font = UIFont(name: textInfo.fontName, size: EditTextInfo.preferredTextSize)
            label.sizeToFit()
            
            var rect = label.bounds.insetBy(dx: -32, dy: -32)
            let maxWidth = containerBounds.width
            if rect.width > maxWidth {
                rect = rect.applying(CGAffineTransform(scaleX: maxWidth/rect.width, y: maxWidth/rect.width))
            }
            
            rect.origin = CGPoint(x: (containerBounds.width - rect.width)/2, y: (containerBounds.height - rect.height)/2)
            return rect.normalizeRect(containerSize: containerBounds.size)
        }
        
        static func predictNormalizedSize(textInfo: EditTextInfo, containerBounds: CGRect) -> CGSize {
            return Info.getInitialNRect(textInfo: textInfo, containerBounds: containerBounds).size
        }
    }
    
    var editTextRender: TextRender? {
        return render as? TextRender
    }
    
    var stickerRender: StickerRender? {
        return render as? StickerRender
    }
    
    var info: Info! {
        didSet {
            updateInfoPosition()
        }
    }
    
    var rotation: CGFloat {
        return info.rotation
    }
    
    var isTransparent: Bool = false {
        didSet {
            if isTransparent {
                render.alpha = 0.3
            } else {
                render.alpha = 1.0
            }
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
    var frameLineWidth = CGFloat(1.5)
    weak var delegate: OverlayComponentDelegate?
    var render: OverlayComponentRender!
    
    var image: UIImage {
        return render.renderImage
    }
    
    //Component only valid in this range of duration.
    var trimPosition: VideoTrimPosition!

    init(info: Info, render: OverlayComponentRender, clipTrimPosition: VideoTrimPosition) {
        super.init(frame: .zero)
        useAutoLayout()
        
        trimPosition = clipTrimPosition
        
        self.info = info
        backgroundColor = .clear
        
        self.render = render
        addSubview(render)
        let margin = CGFloat(32)
        layoutMargins = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        NSLayoutConstraint.activate([
            render.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            render.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            render.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            render.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            ])
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
        width = widthAnchor.constraint(equalToConstant: 0)
        height = heightAnchor.constraint(equalToConstant: 0)
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onMove(sender:))))
        for corner in OverlayComponentCorner.allCases {
            let cornerView = OverlayComponentCornerView(corner: corner).useAutoLayout()
            addSubview(cornerView)
            cornerView.setup()
            cornerViews.append(cornerView)
            registerGesture(cornerView)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return cornerViews.contains { $0.point(inside: convert(point, to: $0), with: event)}
    }
    
    func activeByTap() {
        UIDevice().taptic(level: 1)
        let originTransfrom = self.transform
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                self.transform = originTransfrom.concatenating(CGAffineTransform(scaleX: 0.9, y: 0.9))
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 1, animations: {
                self.transform = originTransfrom
            })
        }, completion: nil)
        delegate?.onActive(component: self)
    }
    
    /// Update layout of overlay component when component model changes.
    func updateInfoPosition() {
        let rect = info.realRect(parentSize: superview!.bounds.size)
        guard rect.width > 0 && rect.height > 0 else { return }
        leading.constant = rect.minX
        top.constant = rect.minY
        width.constant = rect.width
        height.constant = rect.height
        width.isActive = true
        height.isActive = true
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard isActive else { return }
        
        let cornerViewSize = cornerViews.first!.bounds.width
        let frameInset = (cornerViewSize - frameLineWidth)/2 + 2
        let framePath = UIBezierPath(rect: rect.insetBy(dx: frameInset, dy: frameInset))
        UIColor.yellowActiveColor.setStroke()
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
    
    func updateWhenProgressChanged(progress: CMTime) {
        if trimPosition.contains(progress) {
            isTransparent = false
        } else {
            isTransparent = true
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
        guard predictRect.width > 50 && predictRect.height > 50 else {
            return
        }
        
        scaleBy(scale)
        let rotation = extractRotation(translate)
        rotateBy(rotation)
    }
        
    func scaleBy(_ scale: CGFloat, anchorCenter: Bool = false) {
        let containerSize = superview!.bounds.size
        let newSize = info.realRect(parentSize: containerSize).applying(CGAffineTransform(scaleX: scale, y: scale))
        
        guard newSize.width < containerSize.width && newSize.height < containerSize.height
            && newSize.width > 90 && newSize.height > 90 else { return }
        
        info.scaleBy(scale, anchorCenter: anchorCenter)
        updateInfoPosition()
    }
        
    func rotateBy(_ rotation: CGFloat) {
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
        let component = OverlayComponent(info: info.shiftLayout(), render: render.copy(), clipTrimPosition: trimPosition!)
        return component
    }
}

//Edit action
extension OverlayComponent {
    @objc func onEdit(sender: UITapGestureRecognizer) {
        delegate?.onEditComponent(component: self, id: id)
    }
}
