//
//  AdjustView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class AdjustTypeCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                tintColor = .yellowActiveColor
            } else {
                tintColor = .lightText
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        defer {
             isSelected = false
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        if let tintColor = tintColor, let titleView = titleView {
            titleView.textColor = tintColor
        }
    }
}

enum AdjustType: CaseIterable {
    case brightness
    case contrast
    
    var title: String {
        switch self {
        case .brightness:
            return NSLocalizedString("Brightness", comment: "")
        case .contrast:
            return NSLocalizedString("Contrast", comment: "")
        }
    }
    
    var icon: UIImage {
        switch self {
        case .brightness:
            return #imageLiteral(resourceName: "adjust-brightness.png")
        case .contrast:
            return #imageLiteral(resourceName: "adjust-contrast.png")
        }
    }
    
    
}

struct AdjustConfig {
    var value: Double = 0.5
    
    mutating func reset() {
        value = 0.5
    }
}

class AdjustView: UIStackView, Transaction {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout!
    var config = AdjustConfig()
    var activatedType: AdjustType?
    @IBOutlet weak var slider: UISlider!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let views = Bundle.main.loadNibNamed("AdjustView", owner: self, options: nil)!
        let rootView = views.first as! UIView
        rootView.useAutoLayout()
        addSubview(rootView)
        rootView.useSameSizeAsParent()
        
        collectionView.register(UINib(nibName: "AdjustTypeCell", bundle: nil), forCellWithReuseIdentifier: "cell")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commitChange() {
        
    }
    
    func rollbackChange() {
        
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension AdjustView: UICollectionViewDataSource {
    var types: [AdjustType]  {
        return AdjustType.allCases
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return types.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AdjustTypeCell
        let type = types[indexPath.row]
        cell.imageView.image = type.icon
        cell.titleView.text = type.title
        return cell
    }
}


extension AdjustView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = types[indexPath.row]
        guard activatedType != type else { return }
        activatedType = type
        slider.isEnabled = true
        slider.value = 0.5
    }
}
