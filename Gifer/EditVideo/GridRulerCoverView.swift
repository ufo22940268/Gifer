//
//  GridRuleCoverView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

enum GridRulerCoverStatus {
    case solid, adjust
}

class GridRulerCoverView: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateStatus(_ status: GridRulerCoverStatus) {
        if case .solid = status {
            backgroundColor = UIColor.black
        } else if case .adjust = status {            
            backgroundColor = UIColor.black.withAlphaComponent(0.8)
        }
    }
}
