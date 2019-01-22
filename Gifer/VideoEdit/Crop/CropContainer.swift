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
    
    var scrollViewWidthConstraint: NSLayoutConstraint!
    var scrollViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = false
        scrollView.backgroundColor = UIColor.black
        addSubview(scrollView)
        scrollViewWidthConstraint = scrollView.widthAnchor.constraint(equalToConstant: bounds.width)
        scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: bounds.height)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollViewWidthConstraint,
            scrollViewHeightConstraint
            ])
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 2
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            ])
        
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
        gridRulerView.setupVideo(frame: videoFrame)
                
        scrollViewWidthConstraint.constant = videoFrame.width
        scrollViewHeightConstraint.constant = videoFrame.height
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
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            return hitView
        } else {
            return scrollView
        }
    }
    
    func setupCover() {
         let left = GridRulerCoverView()
        addSubview(left)
        let contentView = superview!
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            left.trailingAnchor.constraint(equalTo: gridRulerView.leadingAnchor, constant: gridRulerCornerStrokeWidth),
            left.topAnchor.constraint(equalTo: contentView.topAnchor),
            left.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        
        let top = GridRulerCoverView()
        addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: left.trailingAnchor),
            top.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            top.topAnchor.constraint(equalTo: contentView.topAnchor),
            top.bottomAnchor.constraint(equalTo: gridRulerView.topAnchor, constant: gridRulerCornerStrokeWidth)
            ])

        let right = GridRulerCoverView()
        addSubview(right)
        NSLayoutConstraint.activate([
            right.leadingAnchor.constraint(equalTo: gridRulerView.trailingAnchor, constant: -gridRulerCornerStrokeWidth),
            right.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            right.topAnchor.constraint(equalTo: top.bottomAnchor),
            right.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

        let bottom = GridRulerCoverView()
        addSubview(bottom)
        NSLayoutConstraint.activate([
            bottom.leadingAnchor.constraint(equalTo: left.trailingAnchor),
            bottom.trailingAnchor.constraint(equalTo: right.leadingAnchor),
            bottom.topAnchor.constraint(equalTo: gridRulerView.bottomAnchor, constant: -gridRulerCornerStrokeWidth),
            bottom.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
        
        bringSubviewToFront(gridRulerView)
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
