//
//  VideoControllerAttatchTrim.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoControllerAttatchTrim: TrimController {
    override var faderBackgroundColor: UIColor {
        return UIColor(named: "darkBackgroundColor")!
    }
    
    func update(trimPosition: VideoTrimPosition) {
        let totalWidth = bounds.width
        if let duration = duration, totalWidth > 0 {
            let leftPercent = trimPosition.leftTrim.seconds/duration.seconds
            let rightPercent = (duration.seconds - trimPosition.rightTrim.seconds)/duration.seconds
            leftTrimLeadingConstraint.constant = totalWidth*CGFloat(leftPercent)
            rightTrimTrailingConstraint.constant = -totalWidth*CGFloat(rightPercent)
        }
    }
}

protocol VideoControllerAttachDelegate: class {
    func onAttachChanged(component: OverlayComponent, trimPosition: VideoTrimPosition)
}

class VideoControllerAttachView: UIView {
    
    lazy var galleryView: UIStackView = {
        let view = UIStackView().useAutoLayout()
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }()
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView().useAutoLayout()
        view.addSubview(galleryView)
        galleryView.useSameSizeAsParent()
        return view
    }()
    
    lazy var trimView: VideoControllerAttatchTrim = {
        let view = VideoControllerAttatchTrim().useAutoLayout()
        view.trimDelegate = self
        return view
    }()
    
    var component: OverlayComponent!
    weak var customDelegate: VideoControllerAttachDelegate?
    var duration: CMTime! {
        didSet {
            trimView.duration = duration
            trimView.galleryDuration = duration
        }
    }
    
    init() {
        super.init(frame: .zero)
        useAutoLayout()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28)])
        
        addSubview(scrollView)
        scrollView.useSameSizeAsParent()
        addSubview(trimView)
        trimView.useSameSizeAsParent()
        trimView.setup(galleryView: galleryView)
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onTrimPan(sender:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load(image: UIImage, component: OverlayComponent) {
        self.component = component
        galleryView.subviews.forEach { $0.removeFromSuperview() }
        for _ in 0..<8 {
            let icon = UIImageView().useAutoLayout()
            icon.image = image
            icon.contentMode = .scaleAspectFit
            galleryView.addArrangedSubview(icon)
            NSLayoutConstraint.activate([
                icon.heightAnchor.constraint(equalTo: galleryView.heightAnchor)
                ])
        }
        trimView.update(trimPosition: component.trimPosition)
    }
    
    @objc func onTrimPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: trimView)
        trimView.move(by: translation.x)
        sender.setTranslation(CGPoint.zero, in: trimView)
        
        layoutIfNeeded()
        customDelegate?.onAttachChanged(component: component, trimPosition: trimView.trimPosition)
    }
}

extension VideoControllerAttachView: VideoTrimDelegate {
    func onTrimChangedByTrimer(scrollToPosition: VideoTrimPosition, state: VideoTrimState) {
        customDelegate?.onAttachChanged(component: component, trimPosition: scrollToPosition)
    }
    
    func onTrimChangedByScrollInGallery(trimPosition position: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime) {
    }
}
