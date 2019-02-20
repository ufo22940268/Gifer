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

class FiltersView: UIScrollView {
    
    var previewViews: [FilterPreviewView] = [FilterPreviewView]()
    var stackView: UIStackView!
    weak var customDelegate: FiltersViewDelegate!
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        
        for filter in AllFilters {
            appendPreviewView(filter: filter)
        }
    }
    
    
    func appendPreviewView(filter: YPFilter) {
        let previewView = FilterPreviewView()
        previewView.contentMode = .scaleAspectFill
        previewView.clipsToBounds = true
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
    

    func setPreviewImage(_ image: UIImage) {
        let image = image.resizeImage(60, opaque: false)
        for (index, previewView) in previewViews.enumerated() {
            previewView.setImage(image, with: AllFilters[index])
        }
    }
}
