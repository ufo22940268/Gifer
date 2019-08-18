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

func applyFilterAppliersToImage(_ appliers: [FilterApplier], image: CIImage) -> CIImage {
    var image = image
    for applier in appliers {
        if let newImage = applier(image) {
            image = newImage
        }
    }
    return image
}

enum AdjustType: CaseIterable {
    case brightness
    case contrast
    case saturation
    case warmth
    case vibrance
    
    var title: String {
        switch self {
        case .brightness:
            return NSLocalizedString("Brightness", comment: "")
        case .contrast:
            return NSLocalizedString("Contrast", comment: "")
        case .saturation:
            return NSLocalizedString("Saturation", comment: "")
        case .warmth:
            return NSLocalizedString("Warmth", comment: "")
        case .vibrance:
            return NSLocalizedString("Vibrance", comment: "")
        }
    }
    
    var icon: UIImage {
        switch self {
        case .brightness:
            return #imageLiteral(resourceName: "adjust-brightness.png")
        case .contrast:
            return #imageLiteral(resourceName: "adjust-contrast.png")
        case .saturation:
            return #imageLiteral(resourceName: "adjust-saturation.png")
        case .warmth:
            return #imageLiteral(resourceName: "adjust-warmth.png")
        case .vibrance:
            return #imageLiteral(resourceName: "adjust-vibrance.png")
        }
    }
    
    func makeFilterApplier(with progress: Float) -> FilterApplier {
        return wrapFilter(makeFilter(with: progress))
    }
    
    func wrapFilter(_ filter: CIFilter) -> FilterApplier {
        return {(image: CIImage)  in
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        }
    }
    
    func makeFilter(with progress: Float) -> CIFilter {
        switch self {
        case .brightness:
            return brightnessFilter(with: progress)
        case .contrast:
            return contrastFilter(with: progress)
        case .saturation:
            return saturationFilter(with: progress)
        case .warmth:
            return warmthFilter(with: progress)
        case .vibrance:
            return vibranceFilter(with: progress)
        }
    }
}

extension AdjustType {
    
    func brightnessFilter(with progress: Float) -> CIFilter {
        let brightness = (progress - 0.5)/4
        let filter = CIFilter(name: "CIColorControls", parameters: ["inputBrightness": brightness])!
        return filter
    }
    
    func contrastFilter(with progress: Float) -> CIFilter {
        let contrast = (progress - 0.5)/2 + 1
        let filter = CIFilter(name: "CIColorControls", parameters: ["inputContrast": contrast])!
        return filter
    }
    
    func saturationFilter(with progress: Float) -> CIFilter {
        let contrast = (progress - 0.5)/2 + 1
        let filter = CIFilter(name: "CIColorControls", parameters: ["inputSaturation": contrast])!
        return filter
    }
    
    func warmthFilter(with progress: Float) -> CIFilter {
        let v = CGFloat((progress - 0.5)/0.5)
        if v < 0 {
            return CIFilter(name: "CITemperatureAndTint", parameters: ["inputNeutral": CIVector(x: 2500 + (6500 - 2500)*v, y: 0)])!
        } else {
            return CIFilter(name: "CITemperatureAndTint", parameters: ["inputNeutral": CIVector(x: 6500 + (9500 - 6500)*v, y: 0)])!
        }
        
    }
    
    func vibranceFilter(with progress: Float) -> CIFilter {
        let contrast = (progress - 0.5) + 1
        let filter = CIFilter(name: "CIVibrance", parameters: ["inputAmount": contrast])!
        return filter
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
    
    var filterApplier: FilterApplier? {
        guard value != 0.5 else { return nil }
        return type.makeFilterApplier(with: value)
    }
    
    var filter: CIFilter? {
        guard value != 0.5 else { return nil }
        return type.makeFilter(with: value)
    }
}

protocol AdjustViewDelegate: class {
    func onAdjustFilterChanged(filterAppliers: [FilterApplier])
}

class AdjustView: UIStackView, Transaction {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout!
    var activeType: AdjustType?
    var activeIndex: Int? {
        return configs.firstIndex { $0.type == activeType }
    }
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var restoreButton: UIButton!
    lazy var configs: [AdjustConfig] = {
        return AdjustType.allCases.map { AdjustConfig(type: $0) }
    }()
    
    var filterAppliers: [FilterApplier] {
        return configs.compactMap { $0.filterApplier }
    }
    
    weak var customDelegate: AdjustViewDelegate?
    
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
    
    @IBAction func onRestoreSlider(_ sender: Any) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.slider.setValue(0.5, animated: true)
        }, completion: nil)
        configs[activeIndex!].value = 0.5
        customDelegate?.onAdjustFilterChanged(filterAppliers: filterAppliers)
    }
    
    func commitChange() {
        
    }
    
    func rollbackChange() {
        customDelegate?.onAdjustFilterChanged(filterAppliers: [])
    }
    
    @IBAction func onSliderChanged(_ sender: UISlider) {
        if let activeIndex = activeIndex {
            configs[activeIndex].value = sender.value
        }
        customDelegate?.onAdjustFilterChanged(filterAppliers: filterAppliers)
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
        restoreButton.isEnabled = true
    }
}
