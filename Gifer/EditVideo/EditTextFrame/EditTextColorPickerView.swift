//
//  EditTextColorPickerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class EditTextColorPickerView: UICollectionView {

    init() {
        let layout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: layout)
        backgroundColor = .yellow
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
