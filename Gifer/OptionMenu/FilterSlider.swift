//
//  FilterSlider.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class FilterSlider: UISlider {

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor(named: "darkBackgroundColor")
        maximumValue = 1.0
        minimumValue = 0
        value = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
