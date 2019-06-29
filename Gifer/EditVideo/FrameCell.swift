//
//  CollectionViewCell.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class FrameCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var sequenceView: UILabel!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var magnifierView: UIButton!
    
    var sequence: Int? {
        didSet {
            if let sequence = sequence {
                sequenceView.text = String(sequence + 1)
                sequenceView.isHidden = false
                coverView.isHidden = true
            } else {
                sequenceView.isHidden = true
                coverView.isHidden = false
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBAction func onOpenPreview(_ sender: Any) {
        print("onOpenPreview")
    }
}
