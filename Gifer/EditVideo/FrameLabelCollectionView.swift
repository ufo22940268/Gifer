//
//  FrameLabelCollectionView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class FrameLabelCollectionView: UICollectionView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        dataSource = self
    }
}

extension FrameLabelCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < 2 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "cell1", for: indexPath)
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
        }
    }
    
    
}


