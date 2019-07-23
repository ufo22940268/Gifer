//
//  CropImageViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class CropImageViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func load(image: UIImage) {
        imageView.image = image
    }
}

extension CropImageViewController: CroppableViewControllerProtocol {
    var contentView: UIView {
        return imageView
    }
}
