//
//  TrashView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class TrashView: UIImageView {

    override func awakeFromNib() {
        image = #imageLiteral(resourceName: "trash-2-outline.png")
        translatesAutoresizingMaskIntoConstraints = false
        tintColor = UIColor.white
        backgroundColor = .clear
    }
    
    func openTrash() {
        tintColor = UIColor.red
    }
    
    func closeTrash() {
        tintColor = .white
    }
    
}
