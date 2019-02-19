//
//  FiltersView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class FiltersView: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30)])
        backgroundColor = .yellow
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
