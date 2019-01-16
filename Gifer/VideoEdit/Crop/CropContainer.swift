//
//  CropContainer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class CropContainer: UIView {

    var gridRulerView: GridRulerView!
    
    override func awakeFromNib() {
        gridRulerView = GridRulerView()
        addSubview(gridRulerView)
        gridRulerView.translatesAutoresizingMaskIntoConstraints = false
        let centerX = gridRulerView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerX.identifier = "centerX"
        let centerY = gridRulerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerY.identifier = "centerY"
        let width = gridRulerView.widthAnchor.constraint(equalTo: widthAnchor)
        width.identifier = "width"
        let height = gridRulerView.heightAnchor.constraint(equalTo: heightAnchor)
        height.identifier = "height"
        NSLayoutConstraint.activate([centerX, centerY, width, height])
        gridRulerView.setup()
    }
}
