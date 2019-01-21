//
//  GridRuleCoverView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GridRulerCoverView: UIView {

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }        
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
