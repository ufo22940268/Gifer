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
    var value: Float = 0.5
    var type: AdjustType
    mutating func reset() {
        value = 0.5
    }
    
    init(type: AdjustType) {
        self.type = type
    }
    
    var filter: CIFilter {
        let brightness = (value - 0.5)*2
        let filter = CIFilter(name: "CIColorControls", parameters: ["inputBrightness": brightness])!
        return filter
    }
}

class AdjustView: UIStackView, Transaction {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout!
    var activeType: AdjustType?
    var activeIndex: Int? {
        return configs.firstIndex { $0.type == activeType }
    }
    @IBOutlet weak var slider: UISlider!
    
    lazy var configs: [AdjustConfig] = {
        return  AdjustType.allCases.map { AdjustConfig(type: $0) }
    }()
    
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
    
    @IBAction func onSliderChanged(_ sender: UISlider) {
        if let activeIndex = activeIndex {
            configs[activeIndex].value = sender.value
        }
    }
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
        guard activeType != type else { return }
        activeType = type
        
        let config = configs[indexPath.row]
        slider.isEnabled = true
        slider.value = config.value
    }
}
