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

class VideoControllerAttatchTrim: VideoControllerTrim {
    override var faderBackgroundColor: UIColor {
        return UIColor(named: "darkBackgroundColor")!
    }
}

protocol VideoControllerAttachDelegate: class {
    func onTrimChangedByAttach(component: OverlayComponent, trimPosition: VideoTrimPosition)
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
        return view
    }()
    
    var component: OverlayComponent!
    weak var customDelegate: VideoControllerAttachDelegate?
    var duration: CMTime! {
        didSet {
            trimView.duration = duration
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
    }
    
    @objc func onTrimPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: trimView)
        trimView.move(by: translation.x)
        sender.setTranslation(CGPoint.zero, in: trimView)
        
        layoutIfNeeded()
        customDelegate?.onTrimChangedByAttach(component: component, trimPosition: trimView.trimPosition)
    }
}
