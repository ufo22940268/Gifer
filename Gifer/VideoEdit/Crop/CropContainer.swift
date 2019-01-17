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
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 10

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        imageView.image = #imageLiteral(resourceName: "IMG_3415.JPG")
        imageView.contentMode = .center
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)])
        contentView = imageView

        gridRulerView = GridRulerView()
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
    }
}

extension CropContainer: GridRulerViewDelegate {
    
    func onDragFinished() {
        let toRect = gridRulerView.convert(gridRulerView.bounds, to: contentView)
        print(toRect)
        scrollView.zoom(to: toRect, animated: true)
        UIView.animate(withDuration: 0.3) {
            self.gridRulerView.restoreFrame(in: self.bounds)
            self.layoutIfNeeded()
        }
    }
}

extension CropContainer: UIScrollViewDelegate {
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}
