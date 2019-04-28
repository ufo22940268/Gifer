//
//  FiltersView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        
        let size = self.size
        let aspectRatio =  size.width/size.height
        
        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }
            
        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
}

protocol FiltersViewDelegate: class {
    func onPreviewSelected(filter: YPFilter)
}

class FiltersView: UIStackView {
    
    var previewViews: [FilterPreviewView] = [FilterPreviewView]()
    var stackView: UIStackView!
    weak var customDelegate: FiltersViewDelegate!
    var previewImage: UIImage?
    var selectedIndex: Int = 0
    
    lazy var filterCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 80, height: 80)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).useAutoLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FilterPreviewView.self, forCellWithReuseIdentifier: "cell")
        collectionView.collectionViewLayout = flowLayout
        collectionView.backgroundColor = UIColor(named: "darkBackgroundColor")
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: 80)])
        return collectionView
    } ()
    
    lazy var slider: UISlider = {
        let slider = FilterSlider().useAutoLayout()
        slider.addTarget(self, action: #selector(onSliderChanged(sender:forEvent:)), for: .valueChanged)
        return slider
    }()
    
    lazy var backgroundView: UIView = {
        let view = UIView().useAutoLayout()
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        return view
    }()
    
    var sliderProgress = Double(1.0) {
        didSet {
            filter.progress = sliderProgress
            customDelegate.onPreviewSelected(filter: filter)
        }
    }
    
    var filter: YPFilter!
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        backgroundView.useSameSizeAsParent()
        
        axis = .vertical
        isLayoutMarginsRelativeArrangement = true
        spacing = 8
        
        let sliderContainer = UIView().useAutoLayout()
        sliderContainer.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        sliderContainer.addSubview(slider)
        NSLayoutConstraint.activate([
            sliderContainer.heightAnchor.constraint(equalTo: slider.heightAnchor),
            slider.leadingAnchor.constraint(equalTo: sliderContainer.layoutMarginsGuide.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: sliderContainer.layoutMarginsGuide.trailingAnchor)
            ])
        addArrangedSubview(sliderContainer)
        
        addArrangedSubview(filterCollectionView)
        filter = AllFilters.first!
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onSliderChanged(sender: UISlider, forEvent: UIEvent) {
        sliderProgress = Double(sender.value)
    }
    
    func reloadData() {
        filterCollectionView.reloadData()
    }
}

extension FiltersView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AllFilters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FilterPreviewView
        if let previewImage = previewImage {            
            cell.setImage(previewImage, with: AllFilters[indexPath.row])
        }
        
        cell.isHighlight = indexPath.row == selectedIndex
        return cell
    }
}

extension FiltersView: UICollectionViewDelegate {
    
    func filter(at index: Int) -> YPFilter {
        return AllFilters[index]
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        filter = filter(at: indexPath.row)
        customDelegate.onPreviewSelected(filter: filter)
        
        filterCollectionView.reloadData()
    }
}

extension FiltersView: Transaction {
    
    func commitChange() {

    }
    
    func rollbackChange() {
        customDelegate.onPreviewSelected(filter: NormalFilter)
    }
}
