//
//  CropContainer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class CropContainer: UIView {

    var gridRulerView: GridRulerView!
    @objc weak var contentView: UIView!
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
        
        gridRulerView = GridRulerView(scrollView: scrollView)
        addSubview(gridRulerView)
        gridRulerView.translatesAutoresizingMaskIntoConstraints = false
        let centerX = gridRulerView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerX.identifier = "centerX"
        let centerY = gridRulerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerY.identifier = "centerY"
        let width = gridRulerView.widthAnchor.constraint(equalToConstant: 0)
        width.priority = .defaultLow
        width.identifier = "width"
        let height = gridRulerView.heightAnchor.constraint(equalToConstant: 0)
        height.priority = .defaultLow
        height.identifier = "height"
        NSLayoutConstraint.activate([centerX, centerY, width, height])
        gridRulerView.setup()
        gridRulerView.delegate = self
        
        setupCover()
        
        bringSubviewToFront(gridRulerView)
        
        gridRulerView.isHidden = true
    }
    
    func addContentView(_ contentView: UIView) {
        self.contentView = contentView
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
    }
    
    func setupVideo(frame videoFrame: CGRect) {
        gridRulerView.isHidden = false
        
        gridRulerView.buildGuideConstraints(videoFrame: videoFrame)
        
        gridRulerView.customConstraints.width.constant = videoFrame.width
        gridRulerView.customConstraints.height.constant = videoFrame.height
        gridRulerView.subviews.forEach { (child) in
            child.setNeedsDisplay()
        }
        gridRulerView.frameView.divider.setNeedsDisplay()
    }
    
    func createTestContentView() -> UIView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        scrollView.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(size: scrollView.frame.size).image { (context) in
            #imageLiteral(resourceName: "IMG_3415.JPG").draw(centerIn: CGRect(origin: CGPoint.zero, size: scrollView.frame.size))
        }
        imageView.image = image
        imageView.contentMode = .center
        return imageView
    }
    
    func setupContentView() {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            ])
    }
    
    func setupCover() {
        let left = GridRulerCoverView()
        addSubview(left)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            left.trailingAnchor.constraint(equalTo: gridRulerView.leadingAnchor, constant: gridRulerCornerStrokeWidth),
            left.topAnchor.constraint(equalTo: scrollView.topAnchor),
            left.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
        
        let top = GridRulerCoverView()
        addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: left.trailingAnchor),
            top.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            top.topAnchor.constraint(equalTo: scrollView.topAnchor),
            top.bottomAnchor.constraint(equalTo: gridRulerView.topAnchor, constant: gridRulerCornerStrokeWidth)
            ])
        
        let right = GridRulerCoverView()
        addSubview(right)
        NSLayoutConstraint.activate([
            right.leadingAnchor.constraint(equalTo: gridRulerView.trailingAnchor, constant: -gridRulerCornerStrokeWidth),
            right.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            right.topAnchor.constraint(equalTo: top.bottomAnchor),
            right.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
        
        let bottom = GridRulerCoverView()
        addSubview(bottom)
        NSLayoutConstraint.activate([
            bottom.leadingAnchor.constraint(equalTo: left.trailingAnchor),
            bottom.trailingAnchor.constraint(equalTo: right.leadingAnchor),
            bottom.topAnchor.constraint(equalTo: gridRulerView.bottomAnchor, constant: -gridRulerCornerStrokeWidth),
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
