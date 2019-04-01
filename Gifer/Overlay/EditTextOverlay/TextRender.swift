//
//  TextRender.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class TextRender: UILabel, OverlayComponentRenderable {
    
    override var bounds: CGRect {
        didSet {
            updateFontSize()
        }
    }
    
    init() {
        super.init(frame: .zero)
        useAutoLayout()
        adjustsFontSizeToFitWidth = true
        font = UIFont.systemFont(ofSize: 50)
        textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func copy() -> OverlayComponentRender {
        return self
    }
    
    private func updateFontSize() {
        
    }
}
