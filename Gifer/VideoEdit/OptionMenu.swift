//
//  OptionMenu.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol OptionMenuDelegate: PlaySpeedViewDelegate {
    
}

class OptionMenu: UIView {

    weak var delegate: OptionMenuDelegate?
    var playSpeedView: PlaySpeedView!
    
    override func awakeFromNib() {
        setupPlaySpeedView()
    }
    
    func setupPlaySpeedView() {
        playSpeedView = Bundle.main.loadNibNamed("PlaySpeedView", owner: nil, options: nil)!.first as! PlaySpeedView
        playSpeedView.delegate = delegate
        
        addSubview(playSpeedView)
        NSLayoutConstraint.activate([
            playSpeedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playSpeedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playSpeedView.topAnchor.constraint(equalTo: topAnchor),
            playSpeedView.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }

}
