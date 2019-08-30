//
//  CollectionViewCell.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol FrameCellDelegate: class {
    func onOpenPreview(frame: ImagePlayerFrame)
}

class FrameCellLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width + 8, height: super.intrinsicContentSize.height)
    }
}

class FrameCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var sequenceView: UILabel!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var magnifierView: UIButton!
    weak var delegate: FrameCellDelegate?
    var imageFrame: ImagePlayerFrame!
    
    var sequence: Int? {
        didSet {
            if let sequence = sequence {
                sequenceView.text = String(sequence)
            }
            sequenceView.sizeToFit()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var isSelected: Bool {
        didSet {
            sequenceView.isHidden = isSelected
            coverView.isHidden = !isSelected
        }
    }

    @IBAction func onOpenPreview(_ sender: Any) {
        delegate?.onOpenPreview(frame: imageFrame)
    }
}
