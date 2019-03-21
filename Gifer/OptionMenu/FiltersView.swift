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

class FiltersView: UICollectionView {
    
    var previewViews: [FilterPreviewView] = [FilterPreviewView]()
    var stackView: UIStackView!
    weak var customDelegate: FiltersViewDelegate!
    var previewImage: UIImage?
    var selectedIndex: Int = 0
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 80, height: 80)
        super.init(frame: CGRect.zero, collectionViewLayout: flowLayout)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "darkBackgroundColor")
        
        self.dataSource = self
        self.delegate = self
        register(FilterPreviewView.self, forCellWithReuseIdentifier: "cell")
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 80)])
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        customDelegate.onPreviewSelected(filter: filter(at: indexPath.row))
        
        reloadData()
    }
}

extension FiltersView: Transaction {
    
    func commitChange() {

    }
    
    func rollbackChange() {

    }
}
