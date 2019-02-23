//
//  StickerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit


class StickerView: UIImageView {
    
    var customConstraints: CommonConstraints!
    var guideConstraints: CommonConstraints!
    var guide: UILayoutGuide!

    init(image: UIImage) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        self.image = image
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerEditRecognizer() {
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(onPinch(sender:))))
    }
    
    @objc func onPinch(sender: UIPinchGestureRecognizer) {
        let applyChange = {(constraints: CommonConstraints) in
            constraints.width.constant = constraints.width.constant*sender.scale
            constraints.height.constant = constraints.height.constant*sender.scale
        }
        
        if sender.scale > 0 {
            guideConstraints.snapshot()
            applyChange(guideConstraints)
            if guideOverflow() {
                guideConstraints.rollback()
            } else {
                applyChange(customConstraints)
            }
        }
        sender.scale = 1
    }
    
    func guideOverflow() -> Bool {
        let intersection = guide.layoutFrame.intersection(superview!.bounds)
        return !(almostEqual(intersection.width, guide.layoutFrame.width) && almostEqual(intersection.height, guide.layoutFrame.height))
    }
    
    private func almostEqual(_ l: CGFloat, _ r: CGFloat) -> Bool {
        return abs(l - r) < 1
    }
}
