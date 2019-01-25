//
//  CropContainer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVFoundation

class CropContainer: UIView {

    var gridRulerView: GridRulerView!
    @objc weak var contentView: UIView!
    var scrollView: UIScrollView!
    var scrollViewConstraints: CommonConstraints!
    var videoBounds: CGRect?
    var isEnabled: Bool! {
        didSet {
            scrollView.isUserInteractionEnabled = isEnabled
            gridRulerView.isUserInteractionEnabled = isEnabled
            gridRulerView.isHidden = !isEnabled
        }
    }
    
    override func awakeFromNib() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = false
        scrollView.backgroundColor = UIColor.black
        addSubview(scrollView)
        
        
        let widthConstraint: NSLayoutConstraint = scrollView.widthAnchor.constraint(equalToConstant: 500)
        widthConstraint.priority = .defaultHigh
        let heightConstraint: NSLayoutConstraint = scrollView.heightAnchor.constraint(equalToConstant: 600)
        heightConstraint.priority = .defaultHigh
        scrollViewConstraints = CommonConstraints(centerX: scrollView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                                  centerY: scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
                                                  width: widthConstraint,
                                                  height: heightConstraint
        )
        scrollViewConstraints.activeAll()
        
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
        
        isEnabled = false
    }
    
    func addContentView(_ contentView: UIView) {
        self.contentView = contentView
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            ])
        
    }
    
    func setupVideo(frame videoFrame: CGRect) {
        self.videoBounds = videoFrame
        gridRulerView.setupVideo(frame: videoFrame)
        
        contentView.widthAnchor.constraint(equalToConstant: videoFrame.width).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: videoFrame.height).isActive = true
        scrollViewConstraints.copy(from: gridRulerView.customConstraints)
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
    
    func resetCrop() {
        guard let videoBounds = videoBounds else { return }
        scrollView.zoomScale = 1
        scrollView.contentOffset = CGPoint.zero
        gridRulerView.customConstraints.width.constant = videoBounds.width
        gridRulerView.customConstraints.height.constant = videoBounds.height
        gridRulerView.customConstraints.centerX.constant = 0
        gridRulerView.customConstraints.centerY.constant = 0
        scrollViewConstraints.copy(from: gridRulerView.customConstraints)
    }
}

extension CropContainer: GridRulerViewDelegate {
    
    func onDragFinished() {
        let fromRulerFrame = gridRulerView.frame
        let scrollFrame = self.scrollView.convert(scrollView.frame, from: scrollView.superview!)
        let fromScrollContentSize = self.scrollView.contentSize
        let fromRulerFrameInContentCoordinate = self.scrollView.convert(gridRulerView.frame, from: gridRulerView.superview!)
        
        let toRulerSize = AVMakeRect(aspectRatio: fromRulerFrame.size, insideRect: scrollFrame).size
        
        _ = self.gridRulerView.customConstraints!
        let toWidth = toRulerSize.width
        let toHeight = toRulerSize.height
        let toCenterX = CGFloat(0)
        let toCenterY = CGFloat(0)

        UIView.animate(withDuration: 0.3) {
            self.gridRulerView.customConstraints.width.constant = toWidth
            self.gridRulerView.customConstraints.height.constant = toHeight
            self.gridRulerView.customConstraints.centerX.constant = toCenterX
            self.gridRulerView.customConstraints.centerY.constant = toCenterY
            self.layoutIfNeeded()
            
            let toRulerFrame = self.gridRulerView.frame
            
            let newZoomScale = self.scrollView.zoomScale*toRulerFrame.width/fromRulerFrame.width
            
            self.scrollViewConstraints.copy(from: self.gridRulerView.customConstraints)
            self.scrollView.zoomScale = newZoomScale
            self.layoutIfNeeded()
            
            let contentOriginPostition = self.scrollView.contentSize.applying(CGAffineTransform(scaleX: fromRulerFrameInContentCoordinate.minX/fromScrollContentSize.width, y: fromRulerFrameInContentCoordinate.minY/fromScrollContentSize.height))
            self.scrollView.contentOffset = CGPoint(x: contentOriginPostition.width, y: contentOriginPostition.height)
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
