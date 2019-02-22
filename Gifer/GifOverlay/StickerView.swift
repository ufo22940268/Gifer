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
        if sender.scale > 0 {
            customConstraints.width.constant = customConstraints.width.constant*sender.scale
            customConstraints.height.constant = customConstraints.height.constant*sender.scale
        }
        sender.scale = 1
    }
}
