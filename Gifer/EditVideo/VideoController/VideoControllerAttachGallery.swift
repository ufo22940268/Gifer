//
//  VideoControllerAttachGallery.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class VideoControllerAttachGallery: UICollectionView {

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: flowLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
