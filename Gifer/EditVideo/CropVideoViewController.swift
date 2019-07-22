//
//  CropVideoViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol CroppableViewController {
    var contentView: UIView { get }
    func setContentViewSize(width: CGFloat, height: CGFloat)
}

class CropVideoViewController: UIViewController {

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func load(playerItem: ImagePlayerItem) {
        imagePlayerView.load(playerItem: playerItem)
    }

    func setContentViewSize(width: CGFloat, height: CGFloat) {
        imagePlayerView.constraints.findById(id: "width").constant = width
        imagePlayerView.constraints.findById(id: "height").constant = height
    }
}

extension CropVideoViewController: CroppableViewController {
    var contentView: UIView {
        return imagePlayerView
    }
}
