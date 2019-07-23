//
//  CropVideoViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/22.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

typealias CroppableViewController = UIViewController & CroppableViewControllerProtocol

protocol CroppableViewControllerProtocol {
    var contentView: UIView { get }
}

extension CroppableViewControllerProtocol {
    func setContentViewSize(width: CGFloat, height: CGFloat) {
        contentView.constraints.findById(id: "width").constant = width
        contentView.constraints.findById(id: "height").constant = height
    }
}

class CropVideoViewController: UIViewController {

    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func load(playerItem: ImagePlayerItem) {
        imagePlayerView.load(playerItem: playerItem)
    }
}

extension CropVideoViewController: CroppableViewControllerProtocol {
    var contentView: UIView {
        return imagePlayerView
    }
}
