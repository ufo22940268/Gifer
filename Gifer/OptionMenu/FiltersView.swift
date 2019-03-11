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
    
    func appendPreviewView(filter: YPFilter) {
        let previewView = FilterPreviewView()
        stackView.addArrangedSubview(previewView)
        previewViews.append(previewView)
        
        previewView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onPreviewClicked(sender:))))
    }
    
    @objc func onPreviewClicked(sender: UITapGestureRecognizer) {
        if let target = sender.view as? FilterPreviewView {
            for previewView in previewViews {
                if previewView == target {
                    previewView.isHighlight = true
                } else {
                    previewView.isHighlight = false
                }
            }
            
            customDelegate.onPreviewSelected(filter: target.filter)
        }
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
        
        if let selected = collectionView.indexPathsForSelectedItems?.contains(indexPath) {
            cell.isHighlight = selected
        }
        
        return cell
    }
}

extension FiltersView: UICollectionViewDelegate {
    
    func filter(at index: Int) -> YPFilter {
        return AllFilters[index]
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let previewView = cellForItem(at: indexPath) as? FilterPreviewView {
            previewView.isHighlight = true
        }
        
        customDelegate.onPreviewSelected(filter: filter(at: indexPath.row))
    }
}

extension FiltersView: Transaction {
    
    func commitChange() {

    }
    
    func rollbackChange() {

    }
}
