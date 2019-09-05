//
//  ShotPhotoCountView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/5.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ShotPhotoCountView: UIView {
    
    lazy var countView: UILabel = {
        let view = UILabel().useAutoLayout()
        view.adjustsFontSizeToFitWidth = true
        view.font = UIFont.preferredFont(forTextStyle: .footnote)
        view.textAlignment = .center
        view.textColor = .lightGray
        return view
    }()
    
    var delayHideTask: DispatchWorkItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        layer.cornerRadius = intrinsicContentSize.height/2
        addSubview(countView)
        NSLayoutConstraint.activate([
            countView.centerXAnchor.constraint(equalTo: centerXAnchor),
            countView.centerYAnchor.constraint(equalTo: centerYAnchor),
            countView.widthAnchor.constraint(equalTo: layoutMarginsGuide.widthAnchor),
            countView.heightAnchor.constraint(equalTo: layoutMarginsGuide.heightAnchor),
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 30, height: 30)
    }
    
    func updateCount(_ count: Int) {
        UIView.transition(with: countView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.countView.text = String(count)
        }, completion: nil)
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.alpha = 1
        }) { (_) in
            if let originTask = self.delayHideTask { originTask.cancel() }
            self.delayHideTask = DispatchWorkItem(block: {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.alpha = 0
                })
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: self.delayHideTask!)
        }
    }
}
