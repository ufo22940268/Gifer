//
//  CropContainer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class CropContainer: UIScrollView {

    var gridRulerView: GridRulerView!
    var contentView: UIView!
    var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        clipsToBounds = true
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.widthAnchor.constraint(equalTo: widthAnchor),
            scrollView.heightAnchor.constraint(equalTo: heightAnchor)])
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 2

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        scrollView.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(size: scrollView.frame.size).image { (context) in
            #imageLiteral(resourceName: "IMG_3415.JPG").draw(centerIn: CGRect(origin: CGPoint.zero, size: scrollView.frame.size))            
        }
        imageView.image = image
        imageView.contentMode = .center
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
        contentView = imageView

        gridRulerView = GridRulerView(scrollView: scrollView)
        addSubview(gridRulerView)
        gridRulerView.translatesAutoresizingMaskIntoConstraints = false
        let centerX = gridRulerView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerX.identifier = "centerX"
        let centerY = gridRulerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerY.identifier = "centerY"
        let width = gridRulerView.widthAnchor.constraint(equalTo: widthAnchor)
        width.identifier = "width"
        let height = gridRulerView.heightAnchor.constraint(equalTo: heightAnchor)
        height.identifier = "height"
        NSLayoutConstraint.activate([centerX, centerY, width, height])
        gridRulerView.setup()
        gridRulerView.delegate = self
        
        setupCover()
    }
    
    func setupCover() {
        let left = GridRulerCoverView()
        addSubview(left)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            left.trailingAnchor.constraint(equalTo: gridRulerView.leadingAnchor),
            left.topAnchor.constraint(equalTo: scrollView.topAnchor),
            left.bottomAnchor.constraint(equalTo: gridRulerView.bottomAnchor)
            ])
        
        let top = GridRulerCoverView()
        addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: gridRulerView.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            top.topAnchor.constraint(equalTo: scrollView.topAnchor),
            top.bottomAnchor.constraint(equalTo: gridRulerView.topAnchor)
            ])
        
        let right = GridRulerCoverView()
        addSubview(right)
        NSLayoutConstraint.activate([
            right.leadingAnchor.constraint(equalTo: gridRulerView.trailingAnchor),
            right.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            right.topAnchor.constraint(equalTo: gridRulerView.topAnchor),
            right.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
        
        let bottom = GridRulerCoverView()
        addSubview(bottom)
        NSLayoutConstraint.activate([
            bottom.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: gridRulerView.trailingAnchor),
            bottom.topAnchor.constraint(equalTo: gridRulerView.bottomAnchor),
            bottom.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
                ])
    }
}

extension CropContainer: GridRulerViewDelegate {
    
    func onDragFinished() {
        let toRect = gridRulerView.convert(gridRulerView.bounds, to: contentView)
        scrollView.zoom(to: toRect, animated: true)
        UIView.animate(withDuration: 0.3) {
            self.gridRulerView.restoreFrame(in: self.bounds)
            let restoreToRect = self.gridRulerView.makeAspectFit(in: self.bounds)
            self.scrollView.contentInset = restoreToRect.getEdgeInsets(withContainer: self.bounds)
            
            self.layoutIfNeeded()
        }
    }
}

extension CropContainer: UIScrollViewDelegate {
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

extension CGRect {
    func getEdgeInsets(withContainer container: CGRect) -> UIEdgeInsets {
        return UIEdgeInsets(top: minY, left: minX, bottom: container.maxY - maxY, right: container.maxX - maxX)
    }
}
